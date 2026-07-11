# niri-touchscreen-gestures

Detect 2/3/4-finger (or more) touchscreen swipes and dispatch arbitrary `niri msg action` commands (or any shell command).

## Usage

```bash
niri-touchscreen-gestures --config ~/.config/niri/gestures.toml
```

Optional flags:

- `--threshold N` — minimum pixels of movement to register a swipe (default 60)
- `--device /dev/input/eventN` — explicit evdev device (auto-detection usually works on Framework laptops)

## Config (TOML)

Keys are `<N>-finger-<direction>` where `N` is the finger count and `direction` is one of `up|down|left|right`.

Values are arrays of command arrays; each inner array is passed verbatim to `subprocess.run`.

Example (`~/.config/niri/gestures.toml`):

```toml
"2-finger-up" = [["niri", "msg", "action", "focus-workspace-up"]]
"2-finger-down" = [["niri", "msg", "action", "focus-workspace-down"]]
"3-finger-left" = [["niri", "msg", "action", "focus-column-left"]]
"3-finger-right" = [["niri", "msg", "action", "focus-column-right"]]
"4-finger-up" = [["niri", "msg", "action", "toggle-overview"]]
```

## Requirements

- User must be in the `input` group (or otherwise have read access to the touchscreen evdev node).
- Python ≥ 3.10, `evdev`, `pydantic`/`pydantic-settings`.

## License

MIT
