-- =========================
-- Hyprland (fwbook)
-- =========================
-- Lua config (Hyprland 0.55+; hyprlang is deprecated). Mirrors the niri setup
-- in configs/niri, adapted to Hyprland's native scrolling layout + the noctalia
-- shell. This directory is symlinked to ~/.config/hypr by the skyg hyprland
-- module (skyg.nixos.desktop.tiler.hyprland), defaulting to
-- configs/${hostName}/hypr.
--
-- Split across conf/*.lua and pulled in with require(). The folder is named
-- `conf` (not `hyprland.d`) because require() treats `.` as a path separator.

require("conf/env")
require("conf/general")
require("conf/monitors")
require("conf/inputs")
require("conf/window-rules")
require("conf/keybindings")
require("conf/autostart")
