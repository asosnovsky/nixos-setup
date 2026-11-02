# Bazel build server for slackerbot containers on the same host.
# One NativeLink (cache + scheduler + worker) runs builds on the host CPUs.
#
#   container: bazel build //app  ──grpc──▶  NativeLink (host)  ──▶ host CPUs
#                 ◀── final outputs downloaded (small, same machine)
#
# slackerbot mounts the shared download cache through `binds`. Container root
# is an unprivileged host user; `idmap` only maps file owners on that mount, so
# what it writes in /repo-cache is owned by root on the host.
# TODO: share the Bazel cache with containers without files owned by root.
{ config, lib, pkgs, nativelink, slackerbot, ... }:

with lib;

let
  cfg = config.skyg.nixos.server.services.bazel-build;
  system = pkgs.stdenv.hostPlatform.system;
  # Official Bazel release, checked against its sha256. Containers see
  # /nix/store read-only, so one copy per node serves all of them. Upstream
  # builds only run on NixOS through nix-ld. To bump: change both values.
  bazelVersion = "8.7.0";
  bazelSha256 = "d7606e679b78067c811096fb3d6cf135225b528835ca396e3a4dddf957859544";
  # Copied as-is: patching would break the archive appended to the binary.
  bazelRelease = pkgs.runCommand "bazel-${bazelVersion}-release" { } ''
    install -Dm755 ${pkgs.fetchurl {
      url = "https://releases.bazel.build/${bazelVersion}/release/bazel-${bazelVersion}-linux-x86_64";
      sha256 = bazelSha256;
    }} $out/bin/bazel
  '';

  # `bazel` runs bazelisk on the host and in containers: a repo's
  # .bazelversion wins, otherwise bazelVersion. bazelVersion is pre-entered in
  # bazelisk's cache (format of bazelisk 1.28) as a link to bazelRelease, so it
  # is never downloaded. Other versions download into each user's own cache.
  bazel = pkgs.writeShellScriptBin "bazel" ''
    export USE_BAZEL_FALLBACK_VERSION=''${USE_BAZEL_FALLBACK_VERSION:-silent:${bazelVersion}}
    dl=''${BAZELISK_HOME_LINUX:-''${BAZELISK_HOME:-''${XDG_CACHE_HOME:-$HOME/.cache}/bazelisk}}/downloads
    meta=$dl/metadata/bazelbuild/bazel-${bazelVersion}-linux-x86_64
    if [ ! -e "$dl/sha256/${bazelSha256}/bin/bazel" ] || [ "$(cat "$meta" 2>/dev/null)" != ${bazelSha256} ]; then
      mkdir -p "$dl/sha256" "''${meta%/*}"
      ln -sfn ${bazelRelease} "$dl/sha256/${bazelSha256}"
      printf %s ${bazelSha256} > "$meta"
    fi
    exec ${pkgs.bazelisk}/bin/bazelisk "$@"
  '';

  stateDir = "/var/lib/nativelink";
  # Bazel download cache shared by all containers (files are sha256-checked).
  repoCacheRoot = "/var/lib/bazel-repo-cache";
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
            content_path = "${stateDir}/cas/content";
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

  # Container side `bazel`. Refuses flags that would move work into the
  # container and forces remote actions. The host address comes from
  # /run/bazel-remote.bazelrc (see bazelrc).
  agentBazel = pkgs.writeShellScriptBin "bazel" ''
    set -u
    real=${bazel}/bin/bazel
    enforce=(--spawn_strategy=remote --noremote_local_fallback)

    # Find the command (first word that isn't a startup option) and check flags.
    # Arguments after `--` belong to the program being run, so they're skipped.
    cmd="" at=0 i=0
    for a in "$@"; do
      [ "$a" = "--" ] && break
      case "$a" in
        --spawn_strategy*|--strategy*|--test_strategy*|--remote_executor*|\
        --remote_local_fallback*|--bazelrc*|--ignore_all_rc_files|--nosystem_rc)
          echo "bazel: $a isn't allowed here. Builds must run on the host's build server;" \
            "tell the user instead of working around it." >&2
          exit 2 ;;
      esac
      if [ -z "$cmd" ] && [ "''${a#-}" = "$a" ]; then cmd=$a at=$i; fi
      i=$((i + 1))
    done
    [ -z "$cmd" ] && exec "$real" "$@"
    pre=("''${@:1:at}")
    post=("''${@:at+2}")

    case "$cmd" in
      build|test|run|coverage) exec "$real" "''${pre[@]}" "$cmd" "''${enforce[@]}" "''${post[@]}" ;;
      *) exec "$real" "$@" ;;
    esac
  '';

  # Kept for old habits and docs: same as `bazel build`.
  rbuild = pkgs.writeShellScriptBin "rbuild" ''exec ${agentBazel}/bin/bazel build "$@"'';

  remoteRc = "/run/bazel-remote.bazelrc";

  bazelrc = ''
    # Builds run on the host, so the Bazel server in a container stays small,
    # and exits after 5 idle minutes instead of 3 hours.
    startup --host_jvm_args=-Xmx512m
    startup --host_jvm_args=-XX:+UseSerialGC
    startup --max_idle_secs=300

    # Every action runs on the host; one that can't fails instead of running here.
    build --spawn_strategy=remote
    build --noremote_local_fallback

    # Downloads are shared by all containers on this host. Fetched repo folders
    # are not (unchecked, so one container could tamper with another's).
    common --repository_cache=/repo-cache
    common --repo_contents_cache=/root/.cache/bazel/repo-contents

    build --remote_instance_name=main
    # Final outputs are downloaded into bazel-bin (a few MB, same machine).
    build --remote_download_toplevel
    build --jobs=${toString (cfg.cpuCount * 4)}

    # Rebuild instead of failing when the cache evicts something Bazel needs.
    build --experimental_remote_cache_eviction_retries=5

    build --action_env=PATH=${toolchain}/bin
    build --host_action_env=PATH=${toolchain}/bin
    build --repo_env=CC=${toolchain}/bin/gcc

    # Points plain `bazel` at the host (written at boot). Missing = builds fail.
    try-import ${remoteRc}
  '';

  # Global goose instructions in each container.
  goosehints = ''
    # Bazel builds run on the host, never in this container

    This container is small (a few GB RAM, 1 CPU). `bazel build/test/run` runs
    every action on the host's build server.

    Outputs are downloaded into bazel-bin as usual.
    Flags that change where actions run (--spawn_strategy, --strategy,
    --remote_executor, --bazelrc, ...) are refused on purpose.

    A normal build ends with a line like
    `INFO: 120 processes: 110 remote, 10 internal.` (or "remote cache hit").
    If instead you see `linux-sandbox`, `local` or `processwrapper-sandbox`
    doing the work, or /run/bazel-remote.bazelrc is missing, or a build can't
    reach the remote executor, something is wrong:
    - stop the build (`bazel shutdown`), don't retry it locally,
    - don't remove or override the --remote_* or --spawn_strategy flags,
    - tell the user what you saw, with the error lines.

    Build and test Go code through Bazel (`bazel build`, `bazel test`), not
    `go build` / `go test`: those run here, in this small container. `go mod`
    and other quick `go` commands are fine.
  '';

  # Added to slackerbot's agent system. Uses host packages so bazel and the
  # toolchain match the host exactly.
  agentModule = {
    # No plain bazel/bazelisk on PATH, so the checks in agentBazel can't be skipped by accident.
    environment.systemPackages = [ agentBazel pkgs.go pkgs.git rbuild ];
    environment.etc."bazel.bazelrc".text = bazelrc;
    environment.etc."goose/goosehints".text = goosehints;
    programs.nix-ld.enable = true;

    systemd.tmpfiles.rules = [
      "d /root/.config/goose 0755 root root -"
      "L+ /root/.config/goose/.goosehints - - - - /etc/goose/goosehints"
    ];

    # The host is the default gateway, whose address changes per container,
    # so write it for bazel.bazelrc once the route is up. Doesn't hold up boot.
    systemd.services.bazel-remote-rc = {
      description = "Point Bazel at the host build server";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      path = [ pkgs.iproute2 pkgs.gawk pkgs.coreutils ];
      script = ''
        for _ in $(seq 60); do
          gw=$(ip -4 route show default | awk '{print $3; exit}')
          if [ -n "$gw" ]; then
            echo "build --remote_executor=grpc://$gw:${toString cfg.port}" > ${remoteRc}
            exit 0
          fi
          sleep 1
        done
        echo "no default route after 60s; bazel will build locally" >&2
        exit 1
      '';
    };
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
        description = "slackerbot's agent system with bazel, go, bazelrc and rbuild added. Use for slackerbot's `system`.";
        readOnly = true;
        type = types.package;
        default = (slackerbot.nixosConfigurations.agent.extendModules {
          modules = [ agentModule ];
        }).config.system.build.toplevel;
        # Keeps the manual from building it on every host.
        defaultText = literalExpression "slackerbot agent + bazel, go, bazelrc, rbuild";
      };

      binds = mkOption {
        description = "slackerbot ro_binds / rw_binds that give each container the shared /repo-cache.";
        readOnly = true;
        type = types.attrsOf (types.listOf types.str);
        default = {
          # idmap: every container writes as the same host user, so all can share it.
          rw = [ "${repoCacheRoot}:/repo-cache:idmap" ];
          ro = [ ];
        };
      };
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ bazel pkgs.bazelisk ];
    programs.nix-ld.enable = true; # for the Bazel bazelisk downloads

    systemd.services.nativelink = {
      description = "NativeLink remote cache and build service";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      path = [ toolchain ];
      serviceConfig = {
        ExecStart = "${nativelink.packages.${system}.nativelink}/bin/nativelink ${nativelinkConfig}";
        DynamicUser = true;
        StateDirectory = "nativelink";
        # DynamicUser's state dir is mounted noexec; build actions run from work/.
        ExecPaths = [ "/var/lib/private/nativelink" ];
        UMask = "0022";
        LimitNOFILE = 65536;
        Restart = "on-failure";
      };
    };

    systemd.tmpfiles.rules = [
      # Downloads unused for 30 days are removed (Bazel never cleans this).
      "d ${repoCacheRoot} 0755 root root 30d"
    ];

    # Keep the toolchain from garbage collection.
    system.extraDependencies = [ toolchain ];
  };
}
