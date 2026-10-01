-- =========================
-- Omarchy (nixarchy) shell binds
-- =========================
-- Same keys as the parked noctalia binds (conf/noctalia/binds.lua), mapped to
-- the Omarchy shell's commands. The full set is `omarchy-menu toggle <route>`
-- (root, apps, system, theme, background, capture, hardware, share, reminder)
-- and `omarchy-shell shell toggle omarchy.<panel>` (audio, bluetooth, network,
-- monitor, power, clipboard, emojis, ...).
local mod = "SUPER"

-- Launcher / menu (noctalia: panel-toggle launcher)
hl.bind(mod .. " + Space", hl.dsp.exec_cmd("omarchy-menu toggle"))

-- System menu (noctalia: panel-toggle control-center)
hl.bind(mod .. " + S", hl.dsp.exec_cmd("omarchy-menu toggle system"))

-- Theme menu (noctalia: settings-toggle)
hl.bind(mod .. " + comma", hl.dsp.exec_cmd("omarchy-menu toggle theme"))

-- Dismiss all notifications (noctalia: notification-clear-active)
hl.bind(mod .. " + ALT + L", hl.dsp.exec_cmd("omarchy-shell notifications dismissAll"))

-- ALT + TAB (noctalia's window switcher) has no Omarchy equivalent, so it is
-- left out. The shell's own defaults (SUPER + CTRL + A/B/D for audio/bluetooth/
-- monitor, SUPER + ESCAPE for the system menu) are not bound here.
