# hl-fwdesk/hypr

Steam-console Hyprland config for `hl-fwdesk` (a lounge box attached to a single
1080p HDMI TV). Modeled on `configs/fwbook/hypr` but scoped down for the console
use case — no DMS/noctalia/qs shell, no laptop panel or multi-monitor setup.

It is **baked into the build** (`skyg.nixos.desktop.tiler.hyprland.configLink.mountAsSource`)
and symlinked to `~/.config/hypr` by the skyg hyprland module.

## Files

| Path | Description |
|---|---|
| `hyprland.lua` | Entry point; `require`s the `conf/*.lua` files |
| `conf/env.lua` | Wayland/portal env vars |
| `conf/general.lua` | Scrolling-layout general settings |
| `conf/animations.lua` | Workspace/window animations |
| `conf/monitors.lua` | Single-display (fallback) monitor config |
| `conf/inputs.lua` | Keyboard layout |
| `conf/window-rules.lua` | Float rules for control dialogs |
| `conf/keybindings.lua` | Keyboard/mouse binds |
| `conf/autostart.lua` | Auto-launches Steam Big Picture (`steam -tenfoot`) on start |
| `types/hl.lua` | Lua-language-server type stubs for the `hl` global |