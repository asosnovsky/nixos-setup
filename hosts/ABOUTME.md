# hosts/

One folder per managed machine, plus hardware configs and host-specific scripts.

## Structure

```
hosts/
├── <hostname>/                    # Per-host folder (default.nix is the entry point)
│   ├── default.nix                #   Main config: skyg options, top-level settings
│   ├── packages.nix               #   environment.systemPackages (large hosts only)
│   ├── services.nix               #   Service configs (tailscale, ollama, steam, …)
│   ├── hardware.nix               #   Kernel params, GPU tuning, boot (large hosts only)
│   ├── networking.nix             #   Firewall, NFS mounts, DNS (large hosts only)
│   ├── containers.nix             #   Container service groups (hl-minipc1, hl-minipc2)
│   └── ...                        #   Additional host-specific sub-files as needed
├── <hostname>.hardware-configuration.nix  # Generated — DO NOT EDIT
├── <hostname>.disko.nix                   # Declarative disk layout (hl-fws1 only)
└── scripts/
    ├── fwbook/                          # fwbook-specific shell scripts
    │   ├── functions.sh                 # ZSH functions sourced at shell startup
    │   └── functions.nu                 # NuShell helpers
    ├── fw1/
    │   └── gs.sh                        # gamescope/Steam launch wrapper
    └── hl-minipc1/
        └── buzz-manage.sh               # Buzz stack management CLI
```

## Managed Hosts

| Folder        | Host       | Role                                                                     |
| ------------- | ---------- | ------------------------------------------------------------------------ |
| `fwbook/`     | fwbook     | Framework 13 AMD — personal laptop / daily driver                        |
| `hl-fwdesk/`  | hl-fwdesk  | Framework Desktop AI Max 300 — AI workstation                            |
| `hl-fws1/`    | hl-fws1    | Framework 11th Intel — K3s server node                                   |
| `hl-bigbox1/` | hl-bigbox1 | AI/compute server (NVIDIA + AMD)                                         |
| `hl-bigbox2/` | hl-bigbox2 | NFS storage server                                                       |
| `hl-minipc1/` | hl-minipc1 | Core infra: Gitea, nix-serve, registry, Buzz (docker, `buzz-manage` CLI) |
| `hl-minipc2/` | hl-minipc2 | Container/media server                                                   |
| `hl-minipc3/` | hl-minipc3 | K3s worker node                                                          |
| `hl-pi1/`     | hl-pi1     | Raspberry Pi CM4 (aarch64) — headless server, SSH only                   |
| `hl-pi2/`     | hl-pi2     | Raspberry Pi 4 (aarch64) — headless server, SSH only                     |
| `hl-terra1/`  | hl-terra1  | NFS storage + Jellyfin backup                                            |
| `iso/`        | iso        | Bootable NixOS installer image                                           |

## Rules

- **Do not add `imports = [...]`** to host files — module composition happens in `flake.nix` via `modules/main.nix`
- **Do not edit `*.hardware-configuration.nix`** — these are generated and will be overwritten
- Hosts with a `<hostname>.disko.nix` own their `fileSystems` via disko; if a generated `hardware-configuration.nix` still contains its own `fileSystems` stanzas for the same host, that's a conflict the machine's owner needs to resolve by hand (regenerating or trimming it) — not something to script around
- Host-specific packages and one-off settings belong here; anything reused across hosts belongs in `modules/`
- See `docs/hosts/README.md` for full per-host service/port/package reference

## Rules

- **Do not add `imports = [...]`** to host files — module composition happens in `flake.nix` via `modules/main.nix`
- **Do not edit `*.hardware-configuration.nix`** — these are generated and will be overwritten
- Hosts with a `<hostname>.disko.nix` own their `fileSystems` via disko; if a generated `hardware-configuration.nix` still contains its own `fileSystems` stanzas for the same host, that's a conflict the machine's owner needs to resolve by hand (regenerating or trimming it) — not something to script around
- Host-specific packages and one-off settings belong here; anything reused across hosts belongs in `modules/`
- See `docs/hosts/README.md` for full per-host service/port/package reference
