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
- **Overview:** Pure-Lua workspace overview (`conf/overview.lua`), no plugin. It
  enumerates workspaces via `hl.get_workspaces()` and presents them in a
  `wofi --dmenu` picker, dispatching the chosen workspace with
  `hyprctl dispatch workspace`. Hyprland's Lua API has no "render a workspace
  to a texture" primitive, so this is a switcher-style overview (id, name,
  window count, active/empty/urgent flags) rather than live scaled thumbnails.
  Bound to `Mod+Tab` (niri parity) and `Mod+G`.
- **Overview (plugin, WIP):** ScrollOverview (`conf/scrolloverview.lua`), a
  niri-like overview plugin (github.com/yayuuu/hyprland-scroll-overview), is
  the live-thumbnail alternative. Currently **disabled** (commented out in
  `hyprland.lua`) while it's being debugged; would load via `hl.plugin.load`
  from the `SCROLLOVERVIEW_SO` session variable set in
  `modules/nixos/desktop/tiler/hyprland.nix`.

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
    ├── keybindings.lua          # niri + noctalia binds, scrolling dispatchers (hl.bind/hl.dsp)
    ├── autostart.lua            # noctalia, hypridle via setpriv (hl.on hyprland.start; drops compositor caps)
    ├── overview.lua             # pure-Lua workspace switcher overview (wofi picker, Mod+Tab/Mod+G)
    └── scrolloverview.lua       # ScrollOverview plugin (niri-like, live thumbnails) — WIP/disabled;
                                 # loads via $SCROLLOVERVIEW_SO, require() commented out in hyprland.lua
```

## Bindings without a clean 1:1 niri mapping

- `Mod+Shift+H` (show-hotkey-overlay) — no native Hyprland equivalent; left commented.
- `Mod+Escape` (toggle-keyboard-shortcuts-inhibit) — no native equivalent; omitted.
- `Mod+W` (toggle-column-tabbed-display) — mapped to `hl.dsp.group.toggle()` as the nearest analog.
- `Mod+Tab` (toggle-overview) — pure-Lua overview (`conf/overview.lua`);
  previously the ScrollOverview plugin, and `cyclenext` before that existed.

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
