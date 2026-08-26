# configs/fwbook/hypr/

Host-specific Hyprland configuration for `fwbook`. Symlinked to `~/.config/hypr`
by the `skyg.nixos.desktop.tiler.hyprland` module, which defaults its
`configName` to the machine hostName (`configs/${hostName}/hypr`).

## Why it lives here (and not configs/hypr)

The Hyprland module links `configs/<configName>/hypr` -> `~/.config/hypr`, with
`configName` defaulting to the hostName. Keeping the config under
`configs/fwbook/` lets each host own its own Hyprland tweaks (monitors, etc.)
without stepping on other machines. The old shared `configs/hypr/` (waybar +
hyprpanel) was removed when this replaced it.

## Config format: Lua

Written in **Lua** (`hyprland.lua`), not hyprlang. Hyprland 0.55+ deprecated
hyprlang in favor of Lua, and reads `~/.config/hypr/hyprland.lua`. Files are
split under `conf/` and pulled in with `require()`.

> The folder is named `conf`, not `hyprland.d`, because Hyprland's `require()`
> treats `.` as a path separator — `require("hyprland.d/env")` would resolve to
> `hyprland/d/env`.

## Design

- **Layout:** Hyprland's native `scrolling` layout (0.54+), no plugins required.
  This mirrors niri's scrollable-tiling model. See `conf/general.lua`.
- **Shell:** noctalia (`noctalia-shell`), autostarted in `conf/autostart.lua`
  via `hl.on("hyprland.start", ...)`. There is intentionally no waybar/hyprpanel.
- **Keybinds:** `conf/keybindings.lua` mirrors `configs/niri/shared/binds.kdl`
  and `configs/niri/noctalia/binds.kdl` as closely as Hyprland allows.
- **Overview:** there is no native Hyprland overview, and no overview plugin that
  reliably builds against current Hyprland (hyprexpo was retired from the
  official plugins repo; the community fork chases `main`). `Mod+Tab` falls back
  to `cyclenext` instead of niri's `toggle-overview`.

## Files

```
hypr/
├── hyprland.lua                 # entry point; require()s conf/*.lua in order
├── screen-record.sh             # wf-recorder toggle (bound to Mod+R)
└── conf/
    ├── env.lua                  # cursor size + Wayland/Qt/Electron env hints (hl.env)
    ├── general.lua              # scrolling layout, gaps/border/rounding (hl.config)
    ├── animations.lua           # vertical workspace-switch animation (hl.animation)
    ├── animations.lua           # vertical workspace slide (slidevert), niri-like (hl.animation):
`style = "slidevert"`) to mirror niri's vertically-stacked workspaces, instead of
Hyprland's default horizontal `slide`. Only the `workspaces` leaf is overridden;
everything else stays on Hyprland defaults. Other `workspaces` styles available:
`slide`, `fade`, `slidefade`, `slidefadevert`.
    ├── monitors.lua             # hl.monitor per display (from configs/niri/.../outputs.kdl)
    ├── inputs.lua               # touchpad tap + natural scroll, kb us, hl.gesture
    ├── window-rules.lua         # hl.window_rule floats for small dialogs/utilities
    ├── keybindings.lua          # niri + noctalia binds, scrolling dispatchers (hl.bind/hl.dsp)
    └── autostart.lua            # noctalia, hypridle via UWSM (hl.on hyprland.start)
```

## Bindings without a clean 1:1 niri mapping

- `Mod+Shift+H` (show-hotkey-overlay) — no native Hyprland equivalent; left commented.
- `Mod+Escape` (toggle-keyboard-shortcuts-inhibit) — no native equivalent; omitted.
- `Mod+W` (toggle-column-tabbed-display) — mapped to `hl.dsp.group.toggle()` as the nearest analog.
- `Mod+Tab` (toggle-overview) — no native overview / no buildable plugin; mapped to `cyclenext`.

## Touchpad gestures (niri parity)

niri's 3-finger swipes are mirrored in `conf/inputs.lua`:
- **Horizontal** → `scroll_move` (scroll through columns along the tape)
- **Vertical** → `workspace` (switch workspaces up/down)
- **Mod + swipe (any direction)** → move the whole workspace to the monitor in
  that direction (`movecurrentworkspacetomonitor`), mirroring niri's
  `Mod+TouchpadScroll*` binds. This replaced the old `Mod + mouse wheel` approach.

> The gesture action is `scroll_move` (underscore), not `scrollmove`. The
> `mods = "SUPER"` mask is what lets the Mod + swipe variants coexist with the
> plain swipes. Both require a Hyprland new enough to expose configurable Lua
> gestures (0.55+). The older `scrollmove` name and the `scrollmove` action do
> not exist — they error with "unknown action".

## Behavior deltas from the old hyprlang config

- `Ctrl+Alt+Delete` runs `uwsm stop` (not the `exit` dispatcher). The Hyprland
  wiki warns UWSM users that `exit` breaks the ordered shutdown sequence.
- `Mod+Shift+-/=` (window height) uses a fixed pixel delta instead of a percent,
  since the Lua `window.resize` dispatcher takes pixels, not `%`.
