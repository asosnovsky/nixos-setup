# modules/

All reusable NixOS modules. Every host gets the full module tree via
`modules/main.nix`, which is wired up in `flake.nix` through the `makeNixOs` helper.

## Structure

```
modules/
├── lib.nix            # makeNixOs / makeIso / makeSdImage / eachSystem
│                      #   (registers flake-input NixOS modules:
│                      #    hhstream → services.hyprland-headless-stream)
├── main.nix           # Base module imported by every host: core/ + nixos/ + network-drives.nix
│                      #   + skyg.internalNetworkingMap (global app registry + appNetwork)
├── internal-networking.nix # Renders skyg.internalNetworkingMap → router generalMappings
├── skyg-utils.nix     # makeLinkScript / makeHyperlinkScriptToConfigs (symlink configs/ into ~;
│                      #   a real file or dir in the way moves to <path>.backup.<timestamp>)
├── network-drives.nix # skyg.networkDrives — NFS automount options
├── core/              # User options, binary caches, distributed builds
├── nixos/
│   ├── common/        # Core system settings, user shell setup, config links, networking, SSH, hardware
│   ├── server/        # Server services: K3s/K8s, DNS, AI stack, ARRs, media…
│   └── desktop/       # Desktop: tiler (niri/hyprland), packages, theming, crypto
├── openwrt/           # OpenWrt router config generator
```

## Option Namespace

All custom options live under `skyg.*`. Never introduce options outside this namespace.

```
skyg.user.*               → core/user.nix (applied by nixos/common/user-env.nix)
skyg.configLinks.*        → nixos/common/config-links.nix
skyg.networkDrives.*      → network-drives.nix
skyg.internalNetworkingMap.* → main.nix (global app registry; rendered into router DNS by internal-networking.nix)
skyg.rootDir              → core/default.nix (set by the flake; repo root store path)
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
