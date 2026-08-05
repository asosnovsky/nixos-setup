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

- Installs the `niri-touchscreen-gestures` and `dotool` packages
- Starts two user services: `niri-touchscreen-gestures.service` and `dotoold.service`
- Enables `hardware.uinput` and adds the user to `uinput` (`input` already comes from `tiler.enable`)
- Uses built-in defaults: 3-finger swipes for workspace/column navigation, 4-finger for overview
- Asserts that `niri.enable` is on — the daemon drives niri over its IPC socket

### Options

| Option | Default | Notes |
|---|---|---|
| `touchOutput` | `null` | niri output the panel maps to. **Required when more than one output is enabled** — the daemon refuses to start otherwise. Match `touch { map-to-output }` in the niri config. |
| `device` | `null` | Explicit evdev path; auto-detect fails with multiple touchscreens. |
| `threshold` | `60` | Pixels of movement before a swipe registers. |
| `configFile` | `null` | TOML gesture config. Must exist if set — a missing file is fatal, not a fallback to defaults. |

### Why dotool and not ydotool

Forwarding a tap needs the pointer placed at an absolute position. `ydotool`'s
`mousemove --absolute` does not do that: it emits a warp-to-corner plus a
*relative* delta, so the compositor's pointer acceleration scales it — measured
at exactly 2x on this host, saturating at the screen edge past ~1440px. niri has
no per-device input config, so accel cannot be flattened for just the virtual
device. `dotool` registers a uinput device with a declared absolute axis range
and jumps the cursor via `mouseto`, which acceleration cannot distort.

`dotoold` runs as a long-lived daemon because registering a uinput device carries
a startup delay that would otherwise be paid on every tap.

See `pkgs/niri-touchscreen-gestures/README.md` for gesture configuration details.
