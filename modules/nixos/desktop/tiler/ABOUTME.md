# modules/nixos/desktop/tiler/

Tiling Wayland compositors and their shared plumbing. The shared `tiler.enable` switch
brings in DankMaterialShell (DMS), the gnome-keyring/secrets stack, polkit, and a common set
of Wayland control/capture tools. Each compositor module turns this on automatically.

## Files

```
tiler/
├── default.nix    # skyg.nixos.desktop.tiler.enable — DMS, keyring, polkit, shared packages
├── niri.nix                    # skyg.nixos.desktop.tiler.niri — niri compositor (sets tiler.enable)
├── niri-touchscreen-gestures.nix # skyg.nixos.desktop.tiler.niri.touchscreen-gestures — touchscreen swipe support
├── hyprland.nix                # skyg.nixos.desktop.tiler.hyprland — Hyprland (sets tiler.enable)
└── swww.nix                    # skyg.nixos.desktop.tiler.background — swww/waypaper wallpaper tools
```

## Behaviour

- Enabling either `niri` or `hyprland` sets `skyg.nixos.desktop.tiler.enable = true`, which
  pulls in the shared substrate. You normally enable only the compositor option.
- The shared substrate configures **gnome-keyring as the SSH agent** (so
  `programs.ssh.startAgent = false`), enables polkit, and installs control tools
  (pavucontrol, playerctl, brightnessctl, blueman) and screen-capture tools
  (slurp, satty, wf-recorder).
- `background` is an independent opt-in for swww + waypaper wallpaper management.

## Option Namespace

```
skyg.nixos.desktop.tiler.enable                  → default.nix (usually set indirectly)
skyg.nixos.desktop.tiler.niri.enable
skyg.nixos.desktop.tiler.niri.touchscreen-gestures.enable  # 3/4-finger swipes → niri actions
skyg.nixos.desktop.tiler.hyprland.enable
skyg.nixos.desktop.tiler.background.enable
```

## Conventions

- Don't set `tiler.enable` directly — enable a compositor and let it flip the shared switch.
- Greeter is DMS-managed (`programs.dank-material-shell`); never hand-roll `services.greetd`.
- Keyring provides the SSH agent here — keep `programs.ssh.startAgent` off.

## Touchscreen Gestures (niri only)

When `skyg.nixos.desktop.tiler.niri.touchscreen-gestures.enable = true`:

- Installs `niri-touchscreen-gestures` package
- Starts a user systemd service (`niri-touchscreen-gestures.service`)
- Uses built-in defaults: 3-finger swipes for workspace/column navigation, 4-finger for overview
- Can be customized by placing a TOML config at `~/.config/niri/gestures.toml`
- Requires user to be in the `input` group (done automatically by `tiler.enable`)

See `pkgs/niri-touchscreen-gestures/README.md` for gesture configuration details.
