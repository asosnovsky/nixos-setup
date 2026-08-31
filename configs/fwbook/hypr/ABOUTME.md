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
  via `hl.on("hyprland.start", ...)`. Launched with `setpriv --ambient-caps -all`
  to drop capabilities inherited from the compositor; without it, D-Bus calls
  inside quickshell-based apps fail silently (hyprwm/Hyprland#14844). There is
  intentionally no waybar/hyprpanel.
- **Keybinds:** `conf/keybindings.lua` mirrors `configs/niri/shared/binds.kdl`
  and `configs/niri/dms/binds.kdl` as closely as Hyprland allows.
- **Overview:** A standalone Quickshell config (`configs/fwbook/quickshell/overview/`,
  symlinked to `~/.config/quickshell/overview` by the
  `skyg.nixos.desktop.tiler.quickshell` module) provides a niri-like scrolling
  overview — a vertical stack of workspace rows, each a horizontal strip of
  that workspace's windows with live screencopy previews. It runs as its own
  `qs -c overview` daemon (autostarted in `conf/autostart.lua`), toggled over
  Quickshell's IPC (`qs -c overview ipc call overview toggle`) from `Mod+Tab`
  (`conf/keybindings.lua`) and a 4-finger swipe up/down (`conf/inputs.lua`).
  Arrow keys move the selection, Enter focuses + closes, Esc cancels. See
  `configs/fwbook/quickshell/ABOUTME.md` for the QML implementation.

## Files

```
hypr/
├── hyprland.lua                 # entry point; require()s conf/*.lua in order
├── screen-record.sh             # wf-recorder toggle (bound to Mod+R)
├── xdph.conf                    # xdph screencopy workaround (force_shm); hyprlang, read by xdph itself
├── stylua.toml                  # stylua formatter settings for the Lua files
├── .luarc.json                  # lua-language-server config (uses types/ as library)
├── dms/                         # DMS-auto-generated Hyprland overrides (colors/layout/windowrules);
│                                # not loaded by default — require() them from hyprland.lua to enable
├── types/
│   └── hl.lua                   # EmmyLua type stubs for the `hl` global (editor-only, never executed)
└── conf/
    ├── env.lua                  # cursor size + Wayland/Qt/Electron env hints (hl.env)
    ├── general.lua              # scrolling layout, gaps/border/rounding (hl.config)
    ├── animations.lua           # workspaces slide = "slidevert" (niri-like); only the `workspaces`
    │                            # leaf overridden — other styles: slide, fade, slidefade, slidefadevert
    ├── monitors.lua             # hl.monitor per display (from configs/niri/.../outputs.kdl)
    ├── inputs.lua               # touchpad tap + natural scroll, kb us, hl.gesture
    ├── window-rules.lua         # hl.window_rule floats for small dialogs/utilities
    ├── keybindings.lua          # niri + noctalia binds, scrolling dispatchers (hl.bind/hl.dsp); Mod+Tab toggles the Quickshell overview
    └── autostart.lua            # noctalia, Quickshell overview, hypridle via setpriv (hl.on hyprland.start; drops compositor caps)
```

## Bindings without a clean 1:1 niri mapping

- `Mod+Shift+H` (show-hotkey-overlay) — no native Hyprland equivalent; left commented.
- `Mod+Escape` (toggle-keyboard-shortcuts-inhibit) — no native equivalent; omitted.
- `Mod+W` (toggle-column-tabbed-display) — mapped to `hl.dsp.group.toggle()` as the nearest analog.
- `Mod+Tab` (toggle-overview) — the Quickshell scrolling overview (see above);
  previously a pure-Lua wofi picker, then the ScrollOverview plugin, and
  `cyclenext` before that.

## Touchpad gestures (niri parity)

niri's 3-finger swipes are mirrored in `conf/inputs.lua`:
- **Horizontal** → `scroll_move` (scroll through columns along the tape)
- **Vertical** → `workspace` (switch workspaces up/down)
- **Mod + swipe (any direction)** → move the whole workspace to the monitor in
  that direction (`movecurrentworkspacetomonitor`), mirroring niri's
  `Mod+TouchpadScroll*` binds. This replaced the old `Mod + mouse wheel` approach.
- **4-finger up/down** → open/close the Quickshell scrolling overview (see
  Overview above). `hl.gesture` is a discrete trigger, so there's no
  swipe-progress animation.

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
