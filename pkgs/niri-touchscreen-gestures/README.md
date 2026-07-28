# niri-touchscreen-gestures

A lightweight Python daemon that reads multi-touch events from a touchscreen via [`evdev`](https://python-evdev.readthedocs.io/), detects **swipe/tap gestures**, and either dispatches an action to the [niri](https://github.com/YaLTeR/niri) Wayland compositor or **forwards synthetic input (click/scroll) to whatever window currently has focus**.

**Now with built-in defaults** — just run `niri-touchscreen-gestures` with no arguments to get started with sensible 3- and 4-finger gesture mappings.

It works by:
- Listening to absolute multi-touch (MT) events from an evdev touchscreen device
- Tracking finger start/end positions, timing, and movement vectors
- Classifying swipes (up/down/left/right), taps, double-taps, long-taps, and continuous
  2-finger scroll drags
- Looking up the gesture in a TOML config, scoped by the currently-focused app (queried over
  niri's IPC socket), and either sending an `Action` command to niri or forwarding synthetic
  input via [`wlrctl`](https://git.sr.ht/~brocellous/wlrctl) (niri implements the
  `wlr-virtual-pointer-unstable-v1`/`virtual-keyboard-unstable-v1` protocols natively, so no
  `ydotool`/`uinput`/root daemon is needed)

## Features

- **Pure event-driven**: No polling, uses `evdev.InputDevice.read_loop()`
- **Multi-finger support**: Automatically counts active fingers (2–4+)
- **Tap gestures**: single tap, double tap, and long-press, forwarded as clicks
- **Continuous scroll**: 2-finger vertical drags forward live scroll deltas, not just a one-shot action
- **Per-app rules**: gestures can be scoped to whichever app currently has focus, with a global fallback
- **Configurable mappings**: TOML file maps gestures like `3-finger-left` to niri actions or forwarded input
- **Auto device detection**: Finds the first touchscreen (or accepts explicit `--device`)
- **Robust state machine**: Pure functions for gesture classification with comprehensive tests
- **Lightweight**: Minimal dependencies (`evdev`, `pydantic`, `pydantic-settings`, `wlrctl`)

## Installation

This package is provided as a Nix derivation in this repository:

```nix
# In your configuration
environment.systemPackages = [
  pkgs.niri-touchscreen-gestures
];
```

Or build it directly:

```bash
nix build .#niri-touchscreen-gestures
```

### From PyPI (if published)

```bash
pip install niri-touchscreen-gestures
```

Requires Python 3.10+ and the `input` group (for raw evdev access).

## Usage

The simplest way to run it is with **no arguments** — it now uses sensible built-in defaults for 3- and 4-finger gestures:

```bash
niri-touchscreen-gestures
```

You can still override the defaults:

```bash
# Use a custom config
niri-touchscreen-gestures --config ~/.config/niri/gestures.toml

# Change swipe sensitivity
niri-touchscreen-gestures --threshold 40

# Use a specific device (bypasses auto-detection)
niri-touchscreen-gestures --device /dev/input/event5
```

### Command-line options

- `--config PATH`: Path to TOML configuration file (optional — uses built-in defaults)
- `--threshold N` (default: 60): Minimum pixels of movement to register a swipe
- `--device /dev/input/eventX`: Explicit evdev device (bypasses auto-detection)

The program must run with access to `/dev/input/event*` devices (typically via the `input` group) and with the `NIRI_SOCKET` environment variable set.

## Configuration

The tool ships with **sensible defaults** that match the example below. You only need to provide a config file if you want to customize the mappings.

See [`example-config.toml`](example-config.toml):

```toml
[global]
"3-finger-up" = "FocusWorkspaceDown"
"3-finger-down" = "FocusWorkspaceUp"
"3-finger-left" = "FocusColumnRight"
"3-finger-right" = "FocusColumnLeft"
"4-finger-up" = "ToggleOverview"
"4-finger-down" = "ToggleOverview"

[apps."dev.zed.Zed"]
"1-finger-tap" = "forward:click-left"
"1-finger-double-tap" = "forward:click-right"
"1-finger-long-tap" = "forward:click-right"
"2-finger-scroll" = "forward:scroll"
```

The `[global]` table's mappings are the **built-in defaults**. `[apps."<app-id>"]` tables add
rules that only apply while that app has focus (matched by its Wayland `app_id`, as reported by
niri's `FocusedWindow` IPC query) and take priority over `[global]` for the same key.

Gesture keys:
- `"<N>-finger-<direction>"` — swipe, `direction` = `up`/`down`/`left`/`right`
- `"1-finger-tap"` / `"1-finger-double-tap"` / `"1-finger-long-tap"` — tap gestures
- `"<N>-finger-scroll"` — continuous drag scroll (currently supported for `N = 2`)

Action values:
- A niri action name (see below, or
  [niri's config.rs](https://github.com/YaLTeR/niri/blob/main/src/niri/config.rs))
- `"forward:click-left"` / `"forward:click-right"` / `"forward:scroll"` — synthetic input
  forwarded to the focused window via `wlrctl`

**Tip**: Place a custom config at `~/.config/niri/gestures.toml` and launch the daemon from a user systemd service or your niri startup script.

## Supported niri Actions

Currently typed for these common actions (more can be added easily):

- `FocusWorkspaceUp`
- `FocusWorkspaceDown`
- `FocusColumnLeft`
- `FocusColumnRight`
- `ToggleOverview`

See [`nirictl.py`](niri_touchscreen_gestures/nirictl.py) for the list.

## How It Works

1. **Device Selection**: `touchscreen_identifier.py` scans `/dev/input` for devices with `EV_ABS` capabilities that aren't mice or touchpads.
2. **Event Loop**: Reads raw `EV_ABS` events (`ABS_MT_SLOT`, `ABS_MT_TRACKING_ID`, `ABS_MT_POSITION_X/Y`).
3. **State Tracking**: Maintains per-slot (per-finger) start/current coordinates and start time.
4. **Gesture Detection**: On finger lift (`TRACKING_ID == -1`), classifies a tap/long-tap (low movement) or a swipe (movement past threshold). A lone tap is held for a short debounce window (via a background timer) to see if a second tap follows and it becomes a double-tap. 2-finger vertical drags stream continuous scroll deltas on every position update, instead of waiting for lift.
5. **Focused-app resolution**: Queries niri's `FocusedWindow` IPC request (once per gesture, cached for its duration) and resolves the gesture key against `[apps."<app-id>"]` first, falling back to `[global]`.
6. **Dispatch**: Niri actions are sent as JSON over niri's IPC socket; `forward:*` actions are sent to the focused window via `wlrctl pointer click/scroll`.

All core logic is in `detector/gestures.py` and is unit-tested.

## Development

```bash
# Enter dev shell (includes the package + test deps)
nix develop

# Run tests
pytest

# Run with example config
NIRI_SOCKET=/run/user/$(id -u)/niri/socket \
  niri-touchscreen-gestures --config example-config.toml
```

The project uses:
- [`hatchling`](https://hatch.pypa.io/) for building
- `pydantic` for config validation
- Pure functions where possible for testability

## License

MIT. See [LICENSE](LICENSE) (or the `default.nix` meta).

## See Also

- [niri](https://github.com/YaLTeR/niri) — The scrollable-tiling Wayland compositor
- [niri's IPC](https://github.com/YaLTeR/niri/blob/main/doc/ipc.md) — JSON socket protocol used
- [evdev](https://www.freedesktop.org/software/libevdev/doc/latest/) — Linux input event interface

---

**Part of [nixos-setup](https://github.com/skykanin/nixos-setup)** by Ari Sosnovsky.
