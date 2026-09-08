# hl-pi1/hypr

Minimal Hyprland config for `hl-pi1` (a small clock/calendar display box). It
boots straight into Hyprland (`services.displayManager.autoLogin`) and
auto-launches a single Quickshell shell (`configs/hl-pi1/quickshell/clock/`)
that fills the screen with a big digital clock and a calendar — there is no
noctalia shell, no Steam, and no desktop compositor panel.

Symlinked to `~/.config/hypr` by the `skyg.nixos.desktop.tiler.hyprland` module
(`configName` defaults to the machine hostName).

## Files

| Path | Description |
|---|---|
| `hyprland.lua` | Entry point; `require`s the `conf/*.lua` files |
| `conf/env.lua` | Wayland/Qt env vars |
| `conf/general.lua` | Basic general/decoration settings |
| `conf/monitors.lua` | Single (fallback) monitor config |
| `conf/inputs.lua` | Keyboard layout |
| `conf/window-rules.lua` | Float rules for utility dialogs |
| `conf/keybindings.lua` | Minimal binds: `Super+Return` (foot), `Ctrl+Alt+Delete` (`uwsm stop`) |
| `conf/autostart.lua` | Auto-launches the Quickshell clock (`qs -c clock`) on start |

Shared `hl` type stubs live in `configs/hypr-types/hl.lua` (pointed at by `.luarc.json`).