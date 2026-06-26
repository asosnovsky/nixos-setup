# modules/nixos/server/services/comfyui/

ComfyUI (Stable Diffusion workflow UI) running in Docker with GPU acceleration. Supports both
**ROCm** (AMD) and **CUDA** (NVIDIA) via a `mode` switch, with shared options/assertions in
`shared.nix`.

## Files

```
comfyui/
├── default.nix       # imports shared + rocm + rocm-docker + cuda
├── shared.nix        # skyg.nixos.server.services.comfyui.* — options, firewall, assertions
├── rocm.nix          # ROCm (AMD) path
├── rocm-docker.nix   # ROCm container/image wiring
├── cuda.nix          # CUDA (NVIDIA) path
├── rocm.Containerfile# ROCm image definition
└── init.sh           # Container init script
```

## Behaviour

- `mode` selects `"rocm"` (default) or `"cuda"`. Web UI on `port` (default 8188),
  `openFirewall` defaults to **true**.
- `shared.nix` asserts that Docker, `hardware.graphics`, and `hardware.enableAllFirmware` are
  all enabled — ComfyUI needs the GPU passed through to the container.

## Option Namespace

```
skyg.nixos.server.services.comfyui.enable
skyg.nixos.server.services.comfyui.mode         # "rocm" | "cuda"
skyg.nixos.server.services.comfyui.port         # default 8188
skyg.nixos.server.services.comfyui.openFirewall # default true
```

## Conventions

- Pick the GPU `mode` matching the host hardware; the unused path stays inert.
- This module requires Docker (not Podman) and the relevant `hardware/*` GPU module enabled.
