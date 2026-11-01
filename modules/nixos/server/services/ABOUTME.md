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
  to v1.8.3 because its config format changes) plus `build-materializer`, which
  hardlinks finished outputs from the cache into `/var/lib/build-outputs/<container>`.
  Containers run `rbuild //target` (finds the host as the default gateway) and read
  results at `/outputs`. Plain `bazel` builds remotely too: at boot,
  `bazel-remote-rc` writes the gateway into `/run/bazel-remote.bazelrc`, which the
  container's `/etc/bazel.bazelrc` try-imports (missing = local build). Plain builds
  download final outputs (`--remote_download_toplevel`). The Bazel server is capped at
  512M. Global goose hints (`/root/.config/goose/.goosehints` → `/etc/goose/goosehints`)
  tell goose that a local build means something is wrong: stop and report it. It also exposes `agentSystem` (slackerbot's agent + bazel, go,
  bazelrc, rbuild) and `binds` (slackerbot `ro_binds`/`rw_binds`). Used on hl-fws1
  and hl-fwdesk. Slackerbot must create `ro_binds` source folders, or containers fail
  to start before their first build.
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
