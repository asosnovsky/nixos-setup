# modules/nixos/server/services/

Self-hosted application services. `default.nix` imports each one; every service is an
independent `skyg.nixos.server.services.<name>.enable` flag. Most run as OCI containers via
`virtualisation.oci-containers` (so they honour the Docker/Podman runtime chosen in
`common/containers/`), often backed by NFS volumes.

## Files

```
services/
├── default.nix        # imports the services below
├── ai-services.nix    # skyg.nixos.server.services.ai — ollama + Wyoming (whisper/piper/wake)
├── audiobookshelf.nix # skyg.nixos.server.services.audiobookshelf — audiobook/podcast server
├── jellyfin.nix       # skyg.nixos.server.services.jellyfin — media server (uid/gid 7777)
├── scrypted.nix       # skyg.nixos.server.services.scrypted — NVR (host net, NFS NVR volume)
├── dockge.nix         # skyg.nixos.server.services.dockge — compose stack manager (NFS volumes)
├── openclaw.nix       # skyg.nixos.server.services.openclaw — AI gateway (NOT imported by default)
└── comfyui/           # skyg.nixos.server.services.comfyui — ComfyUI with ROCm/CUDA GPU support
```

## Notable details

- **`ai-services.nix`** runs ollama (GPU-passthrough) and openwakeword as containers and
  enables NixOS-native Wyoming faster-whisper + piper. Opens 11434/10200/10300/10400.
- **`dockge.nix` / `scrypted.nix`** create NFS-backed docker volumes via
  `system.activationScripts` and use `skyg.server.timers` for backups/auto-updates.
- **`openclaw.nix`** is a native systemd service (with agenix-token support and security
  hardening). Note: it is **not** listed in `default.nix`'s imports, so it must be imported
  explicitly if used.

## Option Namespace

```
skyg.nixos.server.services.ai.enable
skyg.nixos.server.services.audiobookshelf.{enable,package,configDir,dataDir}
skyg.nixos.server.services.jellyfin.enable
skyg.nixos.server.services.scrypted.enable
skyg.nixos.server.services.dockge.{enable,openFirewall,port,volumes}
skyg.nixos.server.services.openclaw.{enable,port,gatewayToken,...}
skyg.nixos.server.services.comfyui.{enable,mode,port,openFirewall}
```

## Conventions

- One file per service; gate everything behind `enable` (default `false`).
- Expose an `openFirewall` option instead of opening ports unconditionally.
- Secrets (tokens, credentials) come from agenix — never hardcode them.
- See `GUIDELINES.md` in `modules/nixos/server/` for the full service-authoring pattern.
