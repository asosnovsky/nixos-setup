-- =========================
-- Keybindings
-- =========================
local mod = "SUPER"

-- =========================
-- Apps
-- =========================
hl.bind(mod .. " + T", hl.dsp.exec_cmd("ghostty"))
hl.bind(mod .. " + Q", hl.dsp.window.close())

-- =========================
-- Navigation
-- =========================
hl.bind(mod .. " + left", hl.dsp.focus({ direction = "left" }))
hl.bind(mod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mod .. " + up", hl.dsp.focus({ workspace = "e-1" }))
hl.bind(mod .. " + down", hl.dsp.focus({ workspace = "e+1" }))

-- =========================
-- Window Management
-- =========================
hl.bind(mod .. " + CTRL + right", hl.dsp.layout("swapcol r"))
hl.bind(mod .. " + CTRL + left", hl.dsp.layout("swapcol l"))
hl.bind(mod .. " + F", hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle" }))
hl.bind(mod .. " + SHIFT + F", hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }))
hl.bind(mod .. " + V", hl.dsp.window.float({ action = "toggle" }))

-- =========================
-- Resizing
-- =========================
hl.bind(mod .. " + minus", hl.dsp.layout("colresize -0.1"))
hl.bind(mod .. " + equal", hl.dsp.layout("colresize +0.1"))

-- =========================
-- Screenshots
-- =========================
hl.bind("Print", hl.dsp.exec_cmd('grim -g "$(slurp)" - | satty -f -'))
hl.bind(mod .. " + P", hl.dsp.exec_cmd('grim -g "$(slurp)" - | satty -f -'))

-- =========================
-- Session
-- =========================
-- UWSM: use `uwsm stop` instead of the `exit` dispatcher (ordered shutdown).
hl.bind("CTRL + ALT + Delete", hl.dsp.exec_cmd("uwsm stop"))

-- =========================
-- Mouse drag (move / resize windows)
-- =========================
hl.bind(mod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })
