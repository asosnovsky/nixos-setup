-- =========================
-- Noctalia shell binds
-- =========================
-- Moved out of conf/keybindings.lua. Mirrors configs/niri/noctalia/binds.kdl.
local mod = "SUPER"

-- Window switcher
hl.bind("ALT + TAB", hl.dsp.exec_cmd("noctalia msg window-switcher toggle"))

-- Launcher / control center / settings
hl.bind(mod .. " + Space", hl.dsp.exec_cmd("noctalia msg panel-toggle launcher"))
hl.bind(mod .. " + S", hl.dsp.exec_cmd("noctalia msg panel-toggle control-center"))
hl.bind(mod .. " + comma", hl.dsp.exec_cmd("noctalia msg settings-toggle"))

-- Dismiss all notifications
hl.bind(mod .. " + ALT + L", hl.dsp.exec_cmd("noctalia msg notification-clear-active"))
