# modules/

All reusable NixOS and Home Manager modules. Every host gets the full module tree via
`modules/main.nix`, which is wired up in `flake.nix` through the `makeNixOs` helper.

## Structure

```
modules/
├── lib.nix            # makeNixOs / makeIso / makeHomeManagerUsers / makeDarwinModule / eachSystem
├── main.nix           # Base module imported by every host: core/ + nixos/ + network-drives.nix
├── skyg-utils.nix     # makeHyperlinkScriptToConfigs (symlinks configs/ → ~/.config/)
├── macos.nix          # macOS / nix-darwin module
├── network-drives.nix # skyg.networkDrives — NFS automount options
├── core/              # User, binary caches, distributed builds, macOS workarounds
├── home/              # Home Manager: shell, programs, git, fonts, services
├── nixos/
│   ├── common/        # Core system settings, networking, SSH, QEMU, fonts, hardware
│   ├── server/        # Server services: K3s, Gitea, AI stack, DNS, Dockge, ARRs...
│   └── desktop/       # Desktop: tiler (niri/hyprland), packages, theming, crypto
└── openwrt/           # OpenWrt router config generator
```

## Option Namespace

All custom options live under `skyg.*`. Never introduce options outside this namespace.

```
skyg.user.*               → core/user.nix
skyg.networkDrives.*      → network-drives.nix
skyg.nixos.common.*       → nixos/common/
skyg.nixos.desktop.*      → nixos/desktop/
skyg.nixos.server.*       → nixos/server/
skyg.core.*               → core/
```

## Key Conventions

- All modules gate config with `lib.mkIf cfg.enable { ... }`
- Default for every `enable` option is `false` unless universally required
- New modules go in the most specific subdirectory that matches their scope
- See `docs/modules/README.md` for full option reference and architecture diagram
