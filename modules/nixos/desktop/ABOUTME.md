# modules/nixos/desktop/

Everything that turns a host into a workstation. The whole tree is gated by the master
switch `skyg.nixos.desktop.enable`; individual desktop environments, tilers, and extras
have their own sub-options so a host enables only the stack it actually uses.

## Files

```
desktop/
├── default.nix    # skyg.nixos.desktop.enable — display manager, dbus, pipewire, xdg portals
│                  #                       slimMode — skip Xorg/browser/heavy desktop apps
├── tiler/         # Tiling WMs (niri / hyprland) + DankMaterialShell + swww
├── stylix/        # System-wide theming via Stylix (gruvbox-dark-hard)
├── crypto.nix     # skyg.nixos.desktop.crypto — hardware wallet apps + udev rules
├── printers.nix   # CUPS printing + drivers (always on when desktop enabled)
├── gnome.nix      # skyg.nixos.desktop.gnome — GNOME + pop-shell
├── kde.nix        # skyg.nixos.desktop.kde — Plasma 6
├── cosmic.nix     # skyg.nixos.desktop.cosmic — COSMIC DE
└── fixes/         # skyg.nixos.desktop.fixes — workaround and fixes (e.g., AirPods audio)
```

## How it composes

- `default.nix` (`skyg.nixos.desktop.enable`) provides the shared desktop substrate: display
  manager, dbus, PipeWire (only when enabled), upower, avahi, and the XDG portal set.
  Everything else is opt-in.
- `slimMode` keeps the core substrate + tiler but skips the heavy desktop apps and Xorg
  (`packages.nix`/`wayland.nix`/`x11` were folded into `default.nix`; slim hosts use a
  headless-style desktop such as a clock box).
- The DE/WM modules (`gnome`, `kde`, `cosmic`, `tiler`) are independent enables — pick the
  one(s) a host should offer.
- `printers.nix` activates automatically with the master desktop enable; `crypto` is a
  separate opt-in.

## Option Namespace

```
skyg.nixos.desktop.enable          → default.nix (master switch)
skyg.nixos.desktop.slimMode        → default.nix (minimal desktop, no Xorg/heavy apps)
skyg.nixos.desktop.gnome.enable    → gnome.nix
skyg.nixos.desktop.kde.enable      → kde.nix
skyg.nixos.desktop.cosmic.enable   → cosmic.nix
skyg.nixos.desktop.tiler.*         → tiler/
skyg.nixos.desktop.stylix.enable   → stylix/   (default true)
skyg.nixos.desktop.crypto.enable   → crypto.nix
skyg.nixos.desktop.fixes.*         → fixes/
```

## Notes

- The old `packages.nix`, `wayland.nix`, and `x11/` modules were folded into `default.nix`:
  the desktop apps and Xorg/XWayland now install only in full (non-slim) mode.
- Tiler app groups (`control`, `gnome`, `media`) and Hyprland shell `tools` are opt-in — see
  `tiler/ABOUTME.md`.

## Conventions

- Nothing in this tree should activate unless `skyg.nixos.desktop.enable` is set — gate new
  modules accordingly (most check `config.skyg.nixos.desktop.enable`).
- Greeter/login is handled by DankMaterialShell on tiler hosts; do not configure
  `services.greetd` manually (see the repo-root `GUIDELINES.md`).
