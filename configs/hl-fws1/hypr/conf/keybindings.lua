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

-- =========================
-- Remote Control
-- =========================
---- bottom colors
-- hl.bind("F10", hl.dsp.exec_cmd("")) -- red
hl.bind("F11", hl.dsp.exec_cmd("chromium")) -- green
-- hl.bind("F12", hl.dsp.exec_cmd("")) -- blue
-- hl.bind("XF86Tools", hl.dsp.exec_cmd("")) -- blue

---- bottom 3
-- hl.bind("F8", hl.dsp.exec_cmd("")) -- cog
hl.bind("XF86AudioRecord", hl.dsp.window.close()) -- red dot
-- hl.bind("F9", hl.dsp.exec_cmd("")) -- PVR

---- play controls
hl.bind("XF86AudioRewind", hl.dsp.exec_cmd("playerctl previous"))
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play"))
hl.bind("XF86AudioForward", hl.dsp.exec_cmd("playerctl next"))
hl.bind("XF86AudioStop", hl.dsp.exec_cmd("playerctl stop"))

hl.bind("XF86ChannelUp", hl.dsp.focus({ direction = "right" }))
hl.bind("XF86ChannelDown", hl.dsp.focus({ direction = "left" }))
hl.bind("XF86HomePage", hl.dsp.exec_cmd("dms ipc spotlight toggle"))
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("noctalia msg volume-up"), { locked = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("noctalia msg volume-down"), { locked = true })

---- middle
-- hl.bind("F5", hl.dsp.exec_cmd("")) -- LIVE TV
-- hl.bind("XF86Launch6", hl.dsp.exec_cmd("")) -- TV Series
-- hl.bind("F7", hl.dsp.exec_cmd("")) -- Void
-- hl.bind("XF86Launch5", hl.dsp.exec_cmd("")) -- ⭐ Fav
-- hl.bind("F4", hl.dsp.exec_cmd("")) -- Server
-- hl.bind("Menu", hl.dsp.exec_cmd("")) -- Menu
-- hl.bind("F6", hl.dsp.exec_cmd("")) -- Guide
-- hl.bind("XF86Back", hl.dsp.exec_cmd("")) -- Back
-- hl.bind("F3", hl.dsp.exec_cmd("")) -- Last
-- hl.bind("XF86Info", hl.dsp.exec_cmd("")) -- Info
-- hl.bind("XF86Search", hl.dsp.exec_cmd("")) -- XF86Search
