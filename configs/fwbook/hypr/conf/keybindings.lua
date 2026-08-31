-- =========================
-- Keybindings
-- =========================
local mod = "SUPER"

-- =========================
-- General / Apps
-- =========================
hl.bind(mod .. " + T", hl.dsp.exec_cmd("ghostty"))
hl.bind(mod .. " + Z", hl.dsp.exec_cmd("flatpak run app.zen_browser.zen"))
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

-- for the 4-finger swipe equivalent)
hl.bind(mod .. " + Tab", hl.dsp.exec_cmd("qs -c overview ipc call overview toggle"))
hl.bind(mod .. " + SHIFT + Tab", hl.dsp.focus({ monitor = "+1" }))

-- =========================
-- Window Management
-- =========================
-- hl.bind(mod .. " + CTRL + right", function()
-- 	hl.dispatch(hl.dsp.resize({x = 1, relative = true}))
-- 	hl.dispatch(hl.dsp.layout("swapcol r"))
-- end)
hl.bind(mod .. " + CTRL + right", hl.dsp.layout("swapcol r"))
hl.bind(mod .. " + CTRL + left", hl.dsp.layout("swapcol l"))
-- hl.bind(mod .. " + CTRL + right", hl.dsp.window.move({ direction = "right" }))
-- hl.bind(mod .. " + CTRL + left", hl.dsp.window.move({ direction = "left" }))
hl.bind(mod .. " + CTRL + up", hl.dsp.window.move({ workspace = "r-1", follow = true }))
hl.bind(mod .. " + CTRL + down", hl.dsp.window.move({ workspace = "r+1", follow = true }))
hl.bind(mod .. " + F", hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle" }))
-- hl.bind(mod .. " + F", hl.dsp.layout("colresize +conf"))
hl.bind(mod .. " + SHIFT + F", hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }))
hl.bind(mod .. " + CTRL + F", hl.dsp.layout("fit_into_view"))
hl.bind(mod .. " + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mod .. " + C", hl.dsp.layout("focus current"))

-- =========================
-- Resizing
-- =========================
hl.bind(mod .. " + minus", hl.dsp.layout("colresize -0.1"))
hl.bind(mod .. " + equal", hl.dsp.layout("colresize +0.1"))
hl.bind(mod .. " + SHIFT + minus", hl.dsp.window.resize({ x = 0, y = -50, relative = true }))
hl.bind(mod .. " + SHIFT + equal", hl.dsp.window.resize({ x = 0, y = 50, relative = true }))

-- =========================
-- Screenshots & Recording
-- =========================
hl.bind("Print", hl.dsp.exec_cmd('grim -g "$(slurp)" - | satty -f -'))
hl.bind(mod .. " + P", hl.dsp.exec_cmd('grim -g "$(slurp)" - | satty -f -'))
hl.bind(mod .. " + R", hl.dsp.exec_cmd("~/.config/hypr/screen-record.sh"))

-- =========================
-- Session
-- =========================
-- UWSM: use `uwsm stop` instead of the `exit` dispatcher (ordered shutdown).
hl.bind("CTRL + ALT + Delete", hl.dsp.exec_cmd("uwsm stop"))

-- =========================
-- Monitor Movement
-- =========================
hl.bind(mod .. " + ALT + down", hl.dsp.window.move({ monitor = "d" }))
hl.bind(mod .. " + ALT + left", hl.dsp.window.move({ monitor = "l" }))
hl.bind(mod .. " + ALT + right", hl.dsp.window.move({ monitor = "r" }))
hl.bind(mod .. " + ALT + up", hl.dsp.window.move({ monitor = "u" }))

-- =========================
-- Mouse drag (move / resize windows)
-- =========================
hl.bind(mod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- =========================
-- Noctalia shell (mirrors configs/niri/noctalia/binds.kdl)
-- =========================
hl.bind(mod .. " + Space", hl.dsp.exec_cmd("noctalia msg panel-toggle launcher"))
hl.bind(mod .. " + S", hl.dsp.exec_cmd("noctalia msg panel-toggle control-center"))
hl.bind(mod .. " + comma", hl.dsp.exec_cmd("noctalia msg settings-toggle"))

-- Clipboard history
hl.bind(
    mod .. " + ALT + P",
    hl.dsp.exec_cmd('rofi -modi "clipboard:greenclip print" -show clipboard')
)
-- Dismiss all notifications
hl.bind(mod .. " + ALT + L", hl.dsp.exec_cmd("noctalia msg notification-clear-active"))

-- Media & brightness
hl.bind(mod .. " + SHIFT + up", hl.dsp.exec_cmd("noctalia msg volume-up"))
hl.bind(mod .. " + SHIFT + down", hl.dsp.exec_cmd("noctalia msg volume-down"))
hl.bind(mod .. " + SHIFT + right", hl.dsp.exec_cmd("playerctl next"))
hl.bind(mod .. " + SHIFT + left", hl.dsp.exec_cmd("playerctl previous"))
hl.bind(mod .. " + SHIFT + Space", hl.dsp.exec_cmd("playerctl play-pause"))

hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("noctalia msg volume-up"), { locked = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("noctalia msg volume-down"), { locked = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("noctalia msg volume-mute"), { locked = true })
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("noctalia msg brightness-up"), { locked = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("noctalia msg brightness-down"), { locked = true })
