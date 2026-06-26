# modules/nixos/desktop/

Everything that turns a host into a workstation. The whole tree is gated by the master
switch `skyg.nixos.desktop.enable`; individual desktop environments, tilers, and extras
have their own sub-options so a host enables only the stack it actually uses.

## Files

```
desktop/
├── default.nix    # skyg.nixos.desktop.enable — display manager, dbus, libinput, pipewire, xdg portals
├── wayland.nix    # Wayland session vars (NIXOS_OZONE_WL) + clipboard/utils
├── x11/           # X11 server + libinput-gestures (skyg.nixos.desktop.x11.*)
├── tiler/         # Tiling WMs (niri / hyprland) + DankMaterialShell + swww
├── stylix/        # System-wide theming via Stylix (gruvbox-dark-hard)
├── packages.nix   # Desktop apps: chromium, flatpak, vlc, ghostty, clipboard tools
├── crypto.nix     # skyg.nixos.desktop.crypto — hardware wallet apps + udev rules
├── printers.nix   # CUPS printing + drivers (always on when desktop enabled)
├── gnome.nix      # skyg.nixos.desktop.gnome — GNOME + pop-shell
├── kde.nix        # skyg.nixos.desktop.kde — Plasma 6
└── cosmic.nix     # skyg.nixos.desktop.cosmic — COSMIC DE
```

## How it composes

- `default.nix` (`skyg.nixos.desktop.enable`) provides the shared desktop substrate: display
  manager, dbus, libinput, PipeWire (pulse/jack), upower, avahi, and the full xdg portal set.
- The DE/WM modules (`gnome`, `kde`, `cosmic`, `tiler`) are independent enables — pick the
  one(s) a host should offer.
- `packages.nix`, `wayland.nix`, and `printers.nix` activate automatically with the master
  desktop enable; `crypto` is a separate opt-in.

## Option Namespace

```
skyg.nixos.desktop.enable          → default.nix (master switch)
skyg.nixos.desktop.gnome.enable    → gnome.nix
skyg.nixos.desktop.kde.enable      → kde.nix
skyg.nixos.desktop.cosmic.enable   → cosmic.nix
skyg.nixos.desktop.tiler.*         → tiler/
skyg.nixos.desktop.stylix.enable   → stylix/   (default true)
skyg.nixos.desktop.crypto.enable   → crypto.nix
skyg.nixos.desktop.x11.*           → x11/
```

## Conventions

- Nothing in this tree should activate unless `skyg.nixos.desktop.enable` is set — gate new
  modules accordingly (most check `config.skyg.nixos.desktop.enable`).
- Greeter/login is handled by DankMaterialShell on tiler hosts; do not configure
  `services.greetd` manually (see the repo-root `GUIDELINES.md`).
