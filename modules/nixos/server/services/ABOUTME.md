# modules/nixos/server/services/

Self-hosted application services. `default.nix` imports each one; every service is an
independent `skyg.nixos.server.services.<name>.enable` flag. Most run as OCI containers via
`virtualisation.oci-containers` (so they honour the Docker/Podman runtime chosen in
`common/containers/`), often backed by NFS volumes.

## Files

```
services/
├── default.nix        # imports the services below
├── ai-services.nix    # skyg.nixos.server.services.ai — Wyoming (whisper/piper/wake)
├── bazel-build.nix    # skyg.nixos.server.services.bazel-build — NativeLink Bazel build server for slackerbot containers
├── audiobookshelf.nix # skyg.nixos.server.services.audiobookshelf — audiobook/podcast server
├── jellyfin.nix       # skyg.nixos.server.services.jellyfin — media server (uid/gid 7777)
├── signal-cli.nix     # skyg.nixos.server.services.signal-cli — signal-cli HTTP daemon (Hermes Signal bridge)
├── colibri.nix        # skyg.nixos.server.services.colibri — coli serve HTTP API (GLM-5.2/OLMoE local inference)
└── comfyui/           # skyg.nixos.server.services.comfyui — ComfyUI with ROCm/CUDA GPU support
```

## Notable details

- **`ai-services.nix`** openwakeword as containers and
  enables NixOS-native Wyoming faster-whisper + piper. Opens 11434/10200/10300/10400.
- **`bazel-build.nix`** runs NativeLink (from the `nativelink` flake input, pinned
  to v1.8.3 because its config format changes) as a remote cache and executor for
  slackerbot containers. Used on hl-fws1 and hl-fwdesk. Goal: as little as possible
  runs in a container. Measured on slacker-bot (1 CPU container, 2026-11-01): local
  458 s, remote with no cache 65 s, remote with warm cache 17 s.
  - NativeLink uses `DynamicUser`, whose state folder systemd mounts `noexec`;
    `ExecPaths` re-allows it, or every remote action fails with "Permission denied".
  - Containers get their own `bazel` (`agentBazel`), with no plain bazel/bazelisk on
    PATH. At boot `bazel-remote-rc` writes the gateway into `/run/bazel-remote.bazelrc`,
    which `/etc/bazel.bazelrc` try-imports. Only remote actions are allowed
    (`--spawn_strategy=remote`, no local fallback), so a missing file or unreachable
    host fails the build instead of building in the container. The wrapper refuses
    command-line flags that change this (`--spawn_strategy`, `--strategy*`,
    `--remote_executor`, `--bazelrc`, ...). Flags in a repo's own `.bazelrc` are not
    checked.
  - Final outputs are downloaded into `bazel-bin` (`--remote_download_toplevel`).
    `rbuild` is just `bazel build`. A `/handoff` → `/outputs` path that hardlinked
    outputs from the cache was tried and removed: outputs are a few MB over a local
    link, so it saved nothing (download ~20 s vs handoff ~344 s). Most of that was a
    lock bug: Bazel's server inherits open file handles, so a lock held on an fd in
    the wrapper stays held until the server exits. Close such fds for Bazel (`9>&-`).
  - Still in the container: goose, the Bazel server (512M heap, exits after 5 idle
    minutes) and repository rules, which Bazel can't run remotely.
  - Downloads share one cache per host (`/var/lib/bazel-repo-cache` → `/repo-cache`,
    sha256-checked, 30-day cleanup). Fetched repo folders stay per container
    (`--repo_contents_cache`), since their contents are not checked.
  - Container root is an unprivileged host user, so writable binds (`/repo-cache`)
    use `idmap`; without it the folder shows as `nobody` and the container can't
    write. `idmap` only maps file owners on that mount, so what it writes there is
    owned by root on the host. TODO: share the cache without root-owned files.
  - Global goose hints (`/root/.config/goose/.goosehints` → `/etc/goose/goosehints`):
    a local build means something is wrong (stop and report); build Go through Bazel.
  - Exposes `agentSystem` (slackerbot's agent + bazel, go, bazelrc, rbuild) and
    `binds` (slackerbot `ro_binds`/`rw_binds`). Slackerbot creates missing bind
    source folders, or containers fail to start.
  `bazel` is a bazelisk wrapper on the host and in containers: a repo's
  `.bazelversion` wins, otherwise 8.7.0 (`USE_BAZEL_FALLBACK_VERSION`). Bazel 8.7.0
  is fetched once per node by Nix (official release, sha256-checked) and the wrapper
  enters it into each user's bazelisk cache as a link, so containers share that one
  read-only copy and never download it. Other versions download into each container's
  own `/root/.cache/bazelisk`. Upstream Bazel only runs on NixOS through
  `programs.nix-ld`, enabled on the host and in containers. Bump `bazelVersion` and
  `bazelSha256` together.
- **`colibri.nix`** runs `coli serve` (colibrì's OpenAI-compatible API) as a native systemd
  service. `package` picks the backend (`pkgs.colibri`
  cpu / `pkgs.colibri-rocm`); `environmentFile` supplies `COLI_API_KEY` via agenix instead of
  a CLI flag.

## Option Namespace

```
skyg.nixos.server.services.ai.enable
skyg.nixos.server.services.audiobookshelf.{enable,package,configDir,dataDir}
skyg.nixos.server.services.bazel-build.{enable,cpuCount,cacheGB,port,agentSystem,binds}
skyg.nixos.server.services.jellyfin.enable
skyg.nixos.server.services.signal-cli.{enable,host,port,configDir,account,environmentFile,openFirewall}
skyg.nixos.server.services.colibri.{enable,package,model,host,port,environmentFile,openFirewall,...}
skyg.nixos.server.services.comfyui.{enable,mode,port,openFirewall}
```

## Conventions

- One file per service; gate everything behind `enable` (default `false`).
- Expose an `openFirewall` option instead of opening ports unconditionally.
- Secrets (tokens, credentials) come from agenix — never hardcode them.
- See `GUIDELINES.md` in `modules/nixos/server/` for the full service-authoring pattern.
