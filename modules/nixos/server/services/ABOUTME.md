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
├── audiobookshelf.nix # skyg.nixos.server.services.audiobookshelf — audiobook/podcast server
├── jellyfin.nix       # skyg.nixos.server.services.jellyfin — media server (uid/gid 7777)
├── signal-cli.nix     # skyg.nixos.server.services.signal-cli — signal-cli HTTP daemon (Hermes Signal bridge)
├── colibri.nix        # skyg.nixos.server.services.colibri — coli serve HTTP API (GLM-5.2/OLMoE local inference)
└── comfyui/           # skyg.nixos.server.services.comfyui — ComfyUI with ROCm/CUDA GPU support
```

## Notable details

- **`ai-services.nix`** openwakeword as containers and
  enables NixOS-native Wyoming faster-whisper + piper. Opens 11434/10200/10300/10400.
- **`colibri.nix`** runs `coli serve` (colibrì's OpenAI-compatible API) as a native systemd
  service. `package` picks the backend (`pkgs.colibri`
  cpu / `pkgs.colibri-rocm`); `environmentFile` supplies `COLI_API_KEY` via agenix instead of
  a CLI flag.

## Option Namespace

```
skyg.nixos.server.services.ai.enable
skyg.nixos.server.services.audiobookshelf.{enable,package,configDir,dataDir}
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
