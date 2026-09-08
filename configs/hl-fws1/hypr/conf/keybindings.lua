-- =========================
-- Keybindings
-- =========================
local mod = "SUPER"

-- =========================
-- General / Apps
-- =========================
hl.bind(mod .. " + T", hl.dsp.exec_cmd("ghostty"))
hl.bind(mod .. " + B", hl.dsp.exec_cmd("chromium"))
hl.bind(mod .. " + E", hl.dsp.exec_cmd("wofi-emoji"))
hl.bind(mod .. " + Q", hl.dsp.window.close())

-- =========================
-- Navigation
-- =========================
hl.bind(mod .. " + left", hl.dsp.focus({ direction = "left" }))
hl.bind(mod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mod .. " + up", hl.dsp.focus({ workspace = "e-1" }))
hl.bind(mod .. " + down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mod .. " + Tab", hl.dsp.window.cycle_next())
hl.bind(mod .. " + SHIFT + Tab", hl.dsp.focus({ monitor = "+1" }))
hl.bind(mod .. " + SHIFT + F", hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }))
hl.bind(mod .. " + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mod .. " + C", hl.dsp.layout("focus current"))
hl.bind("ALT + TAB", hl.dsp.window.cycle_next())

-- =========================
-- Resizing
-- =========================
hl.bind(mod .. " + minus", hl.dsp.layout("colresize -0.1"))
hl.bind(mod .. " + equal", hl.dsp.layout("colresize +0.1"))
hl.bind(mod .. " + SHIFT + minus", hl.dsp.window.resize({ x = 0, y = -50, relative = true }))
hl.bind(mod .. " + SHIFT + equal", hl.dsp.window.resize({ x = 0, y = 50, relative = true }))

-- =========================
-- Mouse drag (move / resize windows)
-- =========================
hl.bind(mod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })
