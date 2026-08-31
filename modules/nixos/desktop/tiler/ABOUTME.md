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
├── hyprland.nix                # skyg.nixos.desktop.tiler.hyprland — Hyprland via flake (sets tiler.enable)
├── noctalia.nix                # skyg.nixos.desktop.tiler.noctalia — noctalia shell + per-host config symlink
├── quickshell.nix              # skyg.nixos.desktop.tiler.quickshell — qs package + per-host config symlink
└── swww.nix                    # skyg.nixos.desktop.tiler.background — swww/waypaper wallpaper tools
```

## Behaviour

- Enabling either `niri` or `hyprland` sets `skyg.nixos.desktop.tiler.enable = true`, which
  pulls in the shared substrate. You normally enable only the compositor option.
- Both compositors can be enabled at once (pick the session at the greeter).
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
skyg.nixos.desktop.tiler.hyprland.configName     # per-host config dir (default: hostName)
skyg.nixos.desktop.tiler.noctalia.enable         # standalone noctalia + config symlink
skyg.nixos.desktop.tiler.noctalia.configName     # per-host config dir (default: hostName)
skyg.nixos.desktop.tiler.quickshell.enable       # qs package + config symlink (e.g. fwbook's overview)
skyg.nixos.desktop.tiler.quickshell.configName   # per-host config dir (default: hostName)
skyg.nixos.desktop.tiler.background.enable
```

## Hyprland

`hyprland.nix` runs the latest Hyprland from the `hyprland` flake input (package +
`xdg-desktop-portal-hyprland` kept in sync), launched via UWSM. It:

- Installs the noctalia shell and autostart-friendly tools (grim/slurp/satty,
  wofi/rofi, hypridle, wl-clipboard). There is no waybar/hyprpanel — the shell is noctalia.
- No Hyprland overview plugin — the scrolling overview is a standalone Quickshell
  config (`quickshell.nix`, see below), not a Hyprland plugin.
- Symlinks `~/.config/hypr` -> `configs/<configName>/hypr`, where `configName`
  defaults to `config.skyg.core.hostName` (so `fwbook` -> `configs/fwbook/hypr`).

The config itself is written in **Lua** (`hyprland.lua` + `conf/*.lua`), not
hyprlang — Hyprland 0.55+ deprecated hyprlang in favor of Lua. See
`configs/fwbook/hypr/ABOUTME.md`.

The Hyprland Cachix cache (`hyprland.cachix.org`) is added in
`modules/core/nix-substituters.nix` so the flake build doesn't compile from source.

### Quickshell

`quickshell.nix` installs `pkgs.quickshell` (the `qs` binary) and symlinks
`~/.config/quickshell` -> `configs/<configName>/quickshell`, mirroring the
Hyprland/noctalia modules. It's a general-purpose Quickshell config host, not
Hyprland-specific — `fwbook` uses it for the scrolling overview
(`configs/fwbook/quickshell/overview/`, see
`configs/fwbook/hypr/ABOUTME.md`), a standalone `qs -c overview` process
independent of noctalia/DMS. We previously tried Hyprland overview plugins
(hyprexpo, then a community `hyprland-scroll-overview` fork); both were
dropped as moving targets that chased Hyprland `main` and failed to build
against tagged releases. Quickshell avoids the plugin-ABI churn entirely.

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
