# modules/nixos/desktop/x11/

X11 server setup and touchpad gesture support for desktop hosts.

## Files

```
x11/
├── default.nix      # Enables services.xserver (us layout) when desktop.enable is set
└── lib-gesture.nix  # skyg.nixos.desktop.x11.enableLibGestures — libinput-gestures + tools
```

## Behaviour

- `default.nix` enables `services.xserver` with a US keyboard layout whenever
  `skyg.nixos.desktop.enable` is on (X is kept available even on Wayland-first hosts).
- `lib-gesture.nix` is an independent opt-in that installs `libinput-gestures`, `wmctrl`,
  `xdotool`, adds the user to the `input` group, and symlinks
  `configs/libinput-gestures.conf` into the user's `~/.config`.

## Option Namespace

```
skyg.nixos.desktop.x11.enableLibGestures   # default false
```

## Conventions

- Gesture config is sourced from `configs/libinput-gestures.conf` via an activation symlink —
  edit the config there, not in the module.
