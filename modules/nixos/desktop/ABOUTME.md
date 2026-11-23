# modules/nixos/desktop/

Everything that turns a host into a workstation. The whole tree is gated by the master
switch `skyg.nixos.desktop.enable`; tilers and extras
have their own sub-options so a host enables only the stack it actually uses.

## Files

```
desktop/
├── default.nix    # skyg.nixos.desktop.enable — display manager, dbus, xdg portals
│                  #                       slimMode — skip Xorg/browser/heavy desktop apps
├── tiler/         # Tiling WMs (niri / hyprland) + DankMaterialShell + swww
├── stylix/        # System theming via Stylix (gruvbox-dark-hard) + fixed GTK/Qt app theme links
├── crypto.nix     # skyg.nixos.desktop.crypto — hardware wallet apps + udev rules
├── printers.nix   # CUPS printing + drivers (always on when desktop enabled)
└── fixes/         # skyg.nixos.desktop.fixes — workaround and fixes (e.g., AirPods audio)
```

## How it composes

- `default.nix` (`skyg.nixos.desktop.enable`) provides the shared desktop substrate: display
  manager, dbus, upower, avahi, and the XDG portal set. PipeWire is provided separately by
  `skyg.nixos.common.hardware.pipewire.enable` (see `common/hardware/ABOUTME.md`).
  Everything else is opt-in.
- `slimMode` keeps the core substrate + tiler but skips the heavy desktop apps and Xorg
  (`packages.nix`/`wayland.nix`/`x11` were folded into `default.nix`; slim hosts use a
  headless-style desktop such as a clock box).
- `tiler/` (niri, hyprland) is the only desktop stack; there are no GNOME, KDE or COSMIC
  modules.
- `printers.nix` activates automatically with the master desktop enable; `crypto` is a
  separate opt-in.

## Option Namespace

```
skyg.nixos.desktop.enable          → default.nix (master switch)
skyg.nixos.desktop.slimMode        → default.nix (minimal desktop, no Xorg/heavy apps)
skyg.nixos.desktop.tiler.*         → tiler/
skyg.nixos.desktop.stylix.enable   → stylix/   (default true)
skyg.nixos.desktop.crypto.enable   → crypto.nix
skyg.nixos.desktop.fixes.*         → fixes/
```

## Notes

- The desktop user's `extraGroups` deliberately **excludes `disk`**: raw block-device access
  is equivalent to root and nothing here needs it. Do not re-add it.
- The old `packages.nix`, `wayland.nix`, and `x11/` modules were folded into `default.nix`:
  the desktop apps and Xorg/XWayland now install only in full (non-slim) mode.
- Tiler app groups (`control`, `gnome`, `media`) and Hyprland shell `tools` are opt-in — see
  `tiler/ABOUTME.md`.
- Non-slim desktop sets `xdg.mime.defaultApplications` url-scheme entries to Chromium as a
  system-level fallback (a user-level `~/.config/mimeapps.list` still wins). Hosts like `fwbook`
  additionally pin every handler with a read-only `~/.config/mimeapps.list` linked from
  `configs/fwbook/mimeapps.list`, which also stops apps (e.g. Slack) from re-registering
  themselves as the default browser.
  `fwbook` also routes `http(s)` links through `browser-link-picker` (`hosts/fwbook/browser.nix`),
  a rofi menu that opens the link in the Chromium "Personal" or "Work" profile.

## Conventions

- Nothing in this tree should activate unless `skyg.nixos.desktop.enable` is set — gate new
  modules accordingly (most check `config.skyg.nixos.desktop.enable`).
- Greeter/login is handled by DankMaterialShell on tiler hosts; do not configure
  `services.greetd` manually (see the repo-root `GUIDELINES.md`).
