# Bazel build server for slackerbot containers on the same host.
# One NativeLink (cache + scheduler + worker) runs builds on the host CPUs.
# Final outputs are not sent over the network: a host service hardlinks them
# from NativeLink's cache into a folder each container sees at /outputs.
#
#   container: rbuild //app  ──grpc──▶  NativeLink (host)  ──▶ host CPUs
#                 │ writes build events to /handoff/bep.json
#                 ▼
#   host: build-materializer follows bep.json and hardlinks each finished
#         output into /var/lib/build-outputs/<container>/
#                 ▼
#   container: files appear at /outputs (read-only)
#
# slackerbot mounts the folders through `binds`. Containers run as root with
# no private user IDs, so no uid mapping is needed.
{ config, lib, pkgs, nativelink, slackerbot, ... }:

with lib;

let
  cfg = config.skyg.nixos.server.services.bazel-build;
  system = pkgs.stdenv.hostPlatform.system;

  stateDir = "/var/lib/nativelink";
  handoffRoot = "/var/lib/build-handoff";
  # Must be on the same disk as stateDir, or hardlinks fail (falls back to copies).
  outputsRoot = "/var/lib/build-outputs";
  workerPort = 50061; # host only

  # Tools build actions run with. Same store paths on the host and in containers.
  toolchain = pkgs.buildEnv {
    name = "bazel-action-toolchain";
    paths = with pkgs; [ gcc binutils coreutils bash gnused gnugrep gawk findutils diffutils python3 ];
  };

  # Matches NativeLink v1.8.3 (basic_cas example). Field names change between
  # releases; check them when bumping the flake input.
  instances = f: map (instance_name: { inherit instance_name; } // f) [ "" "main" ];
  nativelinkConfig = pkgs.writeText "nativelink.json" (builtins.toJSON {
    stores = [
      {
        # If any output of a cached result was evicted, report a miss so the
        # action is rebuilt instead of returning a result with missing files.
        name = "AC_MAIN_STORE";
        completeness_checking = {
          backend.filesystem = {
            content_path = "${stateDir}/ac/content";
            temp_path = "${stateDir}/ac/tmp";
            eviction_policy.max_bytes = 10 * 1000 * 1000 * 1000;
          };
          cas_store.ref_store.name = "WORKER_FAST_SLOW_STORE";
        };
      }
      {
        name = "WORKER_FAST_SLOW_STORE";
        fast_slow = {
          fast.filesystem = {
            content_path = "${stateDir}/cas/content"; # materializer links from here
            temp_path = "${stateDir}/cas/tmp";
            eviction_policy.max_bytes = cfg.cacheGB * 1000 * 1000 * 1000;
          };
          slow.noop = { };
        };
      }
    ];

    schedulers = [{
      name = "MAIN_SCHEDULER";
      simple.supported_platform_properties = {
        cpu_count = "minimum";
        OSFamily = "priority";
        "container-image" = "priority";
      };
    }];

    workers = [{
      local = {
        worker_api_endpoint.uri = "grpc://127.0.0.1:${toString workerPort}";
        cas_fast_slow_store = "WORKER_FAST_SLOW_STORE";
        upload_action_result.ac_store = "AC_MAIN_STORE";
        work_directory = "${stateDir}/work";
        platform_properties = {
          cpu_count.values = [ (toString cfg.cpuCount) ];
          OSFamily.values = [ "" ];
          "container-image".values = [ "" ];
        };
      };
    }];

    servers = [
      {
        name = "public";
        # Only container links (ve-*) are trusted; the LAN port stays closed.
        listener.http.socket_address = "0.0.0.0:${toString cfg.port}";
        services = {
          cas = instances { cas_store = "WORKER_FAST_SLOW_STORE"; };
          ac = instances { ac_store = "AC_MAIN_STORE"; };
          execution = instances { cas_store = "WORKER_FAST_SLOW_STORE"; scheduler = "MAIN_SCHEDULER"; };
          capabilities = instances { remote_execution.scheduler = "MAIN_SCHEDULER"; };
          bytestream = instances { cas_store = "WORKER_FAST_SLOW_STORE"; };
        };
      }
      {
        name = "private_workers_servers";
        listener.http.socket_address = "127.0.0.1:${toString workerPort}";
        services = {
          worker_api.scheduler = "MAIN_SCHEDULER";
          admin = { };
          health = { };
        };
      }
    ];

    global.max_open_files = 65536;
  });

  # One long-running service for all containers. When a container drops a
  # "started" marker in its handoff folder, a thread follows its build event
  # file. As each target finishes, it opens each output in the cache and
  # hardlinks it into that container's outputs folder (opening first closes
  # the eviction race). Outputs already evicted are reported back so the
  # container can rebuild them.
  #
  # Handoff folders are written by the containers, so they are untrusted: no
  # symlinks are followed and every destination is checked to stay inside
  # that container's outputs folder.
  #
  # NativeLink v1.8 names cache files d2/<sha256>-<size>-<generation>. The
  # generation is a counter we can't guess, so the folder is indexed and
  # re-read when a file isn't found.
  materializer = pkgs.writeScript "build-materializer" ''
    #!${pkgs.python3}/bin/python3
    import ctypes, errno, fcntl, json, os, re, shutil, sys, threading, time

    HANDOFF_ROOT = "${handoffRoot}"
    OUT_ROOT = "${outputsRoot}"
    DIGESTS = "${stateDir}/cas/content/d2"
    NAME_OK = re.compile(r"^[A-Za-z0-9][A-Za-z0-9._-]*$")
    BLOB = re.compile(r"/blobs/([0-9a-f]{64})/(\d+)")
    FICLONE = 0x40049409
    LIBC = ctypes.CDLL(None, use_errno=True)
    AT_FDCWD, AT_EMPTY_PATH = -100, 0x1000

    def log(*a):
        print(*a, file=sys.stderr, flush=True)

    class CasIndex:
        # Maps "<sha256>-<size>" to the newest file name in the cache.
        def __init__(self):
            self.names, self.at, self.lock = {}, 0.0, threading.Lock()

        def rescan(self):
            # Read the folder at most twice a second, however many threads ask.
            wait = self.at + 0.5 - time.monotonic()
            if wait > 0:
                time.sleep(wait)
            names = {}
            try:
                with os.scandir(DIGESTS) as it:
                    for e in it:
                        key, _, gen = e.name.rpartition("-")
                        if key and gen.isdigit() and int(gen) >= names.get(key, (-1, ""))[0]:
                            names[key] = (int(gen), e.name)
            except FileNotFoundError:
                pass
            self.names, self.at = names, time.monotonic()

        def lookup(self, h, size, refresh):
            key = f"{h}-{size}"
            with self.lock:
                if refresh or key not in self.names:
                    self.rescan()
                hit = self.names.get(key)
            return os.path.join(DIGESTS, hit[1]) if hit else None

    CAS = CasIndex()

    def link_fd(fd, dest):
        # Hardlink the exact inode we hold open (root only). Fails with
        # ENOENT if the file was evicted after we opened it.
        if LIBC.linkat(fd, b"", AT_FDCWD, os.fsencode(dest), AT_EMPTY_PATH) != 0:
            err = ctypes.get_errno()
            raise OSError(err, os.strerror(err), dest)

    def copy_fd(fd, dest):
        # Reflink on btrfs/XFS (no extra disk), plain copy otherwise.
        with open(dest, "wb") as out:
            try:
                fcntl.ioctl(out.fileno(), FICLONE, fd)
            except OSError:
                with os.fdopen(os.dup(fd), "rb") as src:
                    src.seek(0)
                    shutil.copyfileobj(src, out, 1 << 20)

    def place(h, size, dest):
        os.makedirs(os.path.dirname(dest), exist_ok=True)
        tmp = dest + ".materializing"
        if os.path.lexists(tmp):
            os.unlink(tmp)
        if size == 0:
            open(tmp, "wb").close()
            os.replace(tmp, dest)
            return True
        for refresh in (False, True):
            path = CAS.lookup(h, size, refresh)
            if path is None:
                continue
            try:
                fd = os.open(path, os.O_RDONLY | os.O_NOFOLLOW)
            except FileNotFoundError:
                continue  # index was stale; re-read it once
            try:
                head = os.pread(fd, 4, 0)
                if head.startswith(b"\x7fELF") or head.startswith(b"#!"):
                    # Executables get their own copy so chmod never touches the cache.
                    copy_fd(fd, tmp)
                    os.chmod(tmp, 0o755)
                else:
                    try:
                        link_fd(fd, tmp)
                    except OSError as e:
                        if e.errno not in (errno.ENOENT, errno.EXDEV):
                            raise
                        # Evicted after we opened it (or another disk):
                        # the open fd still has the data, so copy it.
                        copy_fd(fd, tmp)
                os.replace(tmp, dest)
                # Renaming a hardlink onto the same file is a no-op that
                # leaves tmp behind (output unchanged since last build).
                if os.path.lexists(tmp):
                    os.unlink(tmp)
                return True
            finally:
                os.close(fd)
        return False

    class Job:
        def __init__(self, name):
            self.name = name
            self.handoff = os.path.join(HANDOFF_ROOT, name)
            self.out = os.path.join(OUT_ROOT, name)
            os.makedirs(self.out, exist_ok=True)
            self.out = os.path.realpath(self.out)
            self.started = os.path.join(self.handoff, "started")
            self.sets = {}
            self.missing = []

        def safe_dest(self, parts):
            dest = os.path.normpath(os.path.join(self.out, *parts))
            if not dest.startswith(self.out + "/"):
                raise ValueError("path escapes outputs folder: " + dest)
            return dest

        def files_in(self, set_id, seen):
            if set_id in seen or set_id not in self.sets:
                return []
            seen.add(set_id)
            s = self.sets[set_id]
            found = list(s.get("files", []))
            for sub in s.get("fileSets", []):
                found += self.files_in(sub["id"], seen)
            return found

        @staticmethod
        def digest_of(f):
            if f.get("digest"):
                return f["digest"], int(f.get("length", 0))
            m = BLOB.search(f.get("uri", ""))
            return (m.group(1), int(m.group(2))) if m else (None, None)

        def handle(self, ev):
            if "namedSetOfFiles" in ev:
                self.sets[ev["id"]["namedSet"]["id"]] = ev["namedSetOfFiles"]
            elif "completed" in ev and ev["completed"].get("success"):
                label = ev["id"]["targetCompleted"]["label"]
                ok, seen = True, set()
                for group in ev["completed"].get("outputGroup", []):
                    for fs in group.get("fileSets", []):
                        for f in self.files_in(fs["id"], seen):
                            h, size = self.digest_of(f)
                            if h is None:
                                continue
                            try:
                                dest = self.safe_dest(f.get("pathPrefix", []) + [f["name"]])
                            except ValueError as e:
                                log(self.name, e)
                                continue
                            if not place(h, size, dest):
                                ok = False
                if not ok:
                    self.missing.append(label)

        def open_bep(self):
            path = os.path.join(self.handoff, "bep.json")
            while os.path.lexists(self.started):
                try:
                    fd = os.open(path, os.O_RDONLY | os.O_NOFOLLOW)
                    return os.fdopen(fd, "r")
                except FileNotFoundError:
                    time.sleep(0.1)
            return None

        def follow(self):
            fh = self.open_bep()
            if fh is None:
                return
            buf, finishing = "", False
            with fh:
                while True:
                    chunk = fh.readline()
                    if not chunk:
                        if finishing:
                            return  # build over and file fully read
                        if not os.path.lexists(self.started):
                            finishing = True  # one more pass for the last lines
                        else:
                            time.sleep(0.05)
                        continue
                    buf += chunk
                    if not buf.endswith("\n"):
                        continue
                    line, buf = buf, ""
                    if line.strip():
                        self.handle(json.loads(line))

        def write_result(self):
            # O_EXCL + O_NOFOLLOW: a container can't aim this at a host file.
            tmp = os.path.join(self.handoff, ".result.tmp")
            if os.path.lexists(tmp):
                os.unlink(tmp)
            fd = os.open(tmp, os.O_WRONLY | os.O_CREAT | os.O_EXCL | os.O_NOFOLLOW, 0o644)
            with os.fdopen(fd, "w") as fh:
                json.dump({"missing": self.missing}, fh)
            os.replace(tmp, os.path.join(self.handoff, "result.json"))

        def run(self):
            try:
                self.follow()
            except Exception as e:
                log(self.name, "build handoff failed:", e)
                self.missing.append("//...")  # tell rbuild to fall back to a download
                while os.path.lexists(self.started):
                    time.sleep(0.1)
            try:
                self.write_result()
            except Exception as e:
                log(self.name, "could not write result:", e)

    active, lock = set(), threading.Lock()

    def worker(name):
        try:
            Job(name).run()
        finally:
            with lock:
                active.discard(name)

    os.makedirs(HANDOFF_ROOT, exist_ok=True)
    while True:
        for name in os.listdir(HANDOFF_ROOT):
            if not NAME_OK.match(name):
                continue
            d = os.path.join(HANDOFF_ROOT, name)
            if os.path.islink(d) or not os.path.isdir(d):
                continue
            if not os.path.lexists(os.path.join(d, "started")):
                continue
            with lock:
                if name in active:
                    continue
                active.add(name)
            threading.Thread(target=worker, args=(name,), daemon=True).start()
        time.sleep(0.2)
  '';

  # Container side: `rbuild //target ...` instead of `bazel build`.
  # The host is the container's default gateway (ve-* addresses are not fixed).
  rbuild = pkgs.writeShellScriptBin "rbuild" ''
    set -u
    H=/handoff
    gw=$(${pkgs.iproute2}/bin/ip -4 route show default | ${pkgs.gawk}/bin/awk '{print $3; exit}')
    if [ -z "$gw" ]; then
      echo "rbuild: no default route, can't find the build server" >&2
      exit 1
    fi
    remote=--remote_executor=grpc://$gw:${toString cfg.port}
    rm -f $H/bep.json $H/result.json
    touch $H/started
    ${pkgs.bazel}/bin/bazel build "$remote" --remote_download_minimal --build_event_json_file=$H/bep.json "$@"
    rc=$?
    rm -f $H/started
    for _ in $(seq 600); do [ -f $H/result.json ] && break; sleep 0.1; done
    if [ ! -f $H/result.json ]; then
      echo "rbuild: host did not hand back outputs" >&2
      exit 1
    fi
    mapfile -t missing < <(${pkgs.jq}/bin/jq -r '.missing[]' $H/result.json)
    if [ ''${#missing[@]} -gt 0 ]; then
      # Rare: outputs were evicted before the host could link them. Bazel
      # finds them gone, rebuilds them, and downloads them over the network.
      echo "rbuild: rebuilding ''${#missing[@]} evicted target(s)" >&2
      ${pkgs.bazel}/bin/bazel build "$remote" --remote_download_toplevel "''${missing[@]}" || rc=$?
    fi
    echo "rbuild: outputs are in /outputs" >&2
    exit $rc
  '';

  bazelrc = ''
    build --remote_instance_name=main
    build --remote_download_minimal
    build --jobs=${toString (cfg.cpuCount * 4)}

    # Rebuild instead of failing when the cache evicts something Bazel needs.
    build --experimental_remote_cache_eviction_retries=5

    build --action_env=PATH=${toolchain}/bin
    build --host_action_env=PATH=${toolchain}/bin
    build --repo_env=CC=${toolchain}/bin/gcc
  '';

  # Added to slackerbot's agent system. Uses host packages so bazel and the
  # toolchain match the host exactly.
  agentModule = {
    environment.systemPackages = [ pkgs.bazel pkgs.git rbuild ];
    environment.etc."bazel.bazelrc".text = bazelrc;
  };
in
{
  options = {
    skyg.nixos.server.services.bazel-build = {
      enable = mkEnableOption "Bazel build server (NativeLink) for slackerbot containers";

      cpuCount = mkOption {
        description = "CPU threads the host worker offers to builds.";
        type = types.ints.positive;
      };

      cacheGB = mkOption {
        description = "Size of the build cache in GB.";
        default = 100;
        type = types.ints.positive;
      };

      port = mkOption {
        description = "Port containers reach NativeLink on (container links only).";
        default = 50051;
        type = types.port;
      };

      agentSystem = mkOption {
        description = "slackerbot's agent system with bazel, bazelrc and rbuild added. Use for slackerbot's `system`.";
        readOnly = true;
        type = types.package;
        default = (slackerbot.nixosConfigurations.agent.extendModules {
          modules = [ agentModule ];
        }).config.system.build.toplevel;
        # Keeps the manual from building it on every host.
        defaultText = literalExpression "slackerbot agent + bazel, bazelrc, rbuild";
      };

      binds = mkOption {
        description = "slackerbot ro_binds / rw_binds that give each container /handoff and /outputs.";
        readOnly = true;
        type = types.attrsOf (types.listOf types.str);
        default = {
          rw = [ "${handoffRoot}/{machine}:/handoff" ];
          ro = [ "${outputsRoot}/{machine}:/outputs" ];
        };
      };
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ pkgs.bazel ];

    systemd.services.nativelink = {
      description = "NativeLink remote cache and build service";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      path = [ toolchain ];
      serviceConfig = {
        ExecStart = "${nativelink.packages.${system}.nativelink}/bin/nativelink ${nativelinkConfig}";
        DynamicUser = true;
        StateDirectory = "nativelink";
        # Cached files must be readable by the materializer and containers.
        UMask = "0022";
        LimitNOFILE = 65536;
        Restart = "on-failure";
      };
    };

    systemd.services.build-materializer = {
      description = "Hand Bazel outputs to slackerbot containers";
      wantedBy = [ "multi-user.target" ];
      after = [ "nativelink.service" ];
      serviceConfig = {
        ExecStart = "${materializer}"; # root: needed to link cache files
        UMask = "0022";
        Restart = "always";
      };
    };

    # Outputs older than 7 days are removed. Hardlinked files keep their data
    # alive after NativeLink evicts them, so this is what frees that space.
    # `e` ages what's inside each container's folder, never the folder itself
    # (it is a live bind mount source).
    systemd.tmpfiles.rules = [
      "d ${handoffRoot} 0755 root root -"
      "d ${outputsRoot} 0755 root root -"
      "e ${outputsRoot}/* - - - 7d"
    ];

    # Keep the toolchain from garbage collection.
    system.extraDependencies = [ toolchain ];
  };
}
