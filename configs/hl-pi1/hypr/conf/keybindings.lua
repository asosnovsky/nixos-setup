-- =========================
-- Keybindings
-- =========================
-- Minimal: a terminal escape hatch and a way to shut the session down.
local mod = "SUPER"

hl.bind(mod .. " + T", hl.dsp.exec_cmd("foot"))
hl.bind("CTRL + ALT + Delete", hl.dsp.exec_cmd("uwsm stop"))
