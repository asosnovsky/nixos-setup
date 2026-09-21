-- =========================
-- Input
-- =========================
hl.config({
    input = {
        kb_layout = "us",
        follow_mouse = 1,
        touchpad = {
            natural_scroll = true,
            disable_while_typing = true,
        },
    },
})

hl.gesture({ fingers = 3, direction = "horizontal", action = "scroll_move" })
hl.gesture({ fingers = 3, direction = "vertical", action = "workspace" })

-- Mod + 3-finger swipe: move the whole workspace to the monitor in that
-- direction (mirrors niri's Mod+TouchpadScroll* binds).
hl.gesture({
    fingers = 3,
    direction = "up",
    mods = "SUPER",
    action = function()
        hl.exec_cmd("hyprctl dispatch movecurrentworkspacetomonitor u")
    end,
})
hl.gesture({
    fingers = 3,
    direction = "down",
    mods = "SUPER",
    action = function()
        hl.exec_cmd("hyprctl dispatch movecurrentworkspacetomonitor d")
    end,
})
hl.gesture({
    fingers = 3,
    direction = "left",
    mods = "SUPER",
    action = function()
        hl.exec_cmd("hyprctl dispatch movecurrentworkspacetomonitor l")
    end,
})
hl.gesture({
    fingers = 3,
    direction = "right",
    mods = "SUPER",
    action = function()
        hl.exec_cmd("hyprctl dispatch movecurrentworkspacetomonitor r")
    end,
})
hl.gesture({
    fingers = 4,
    direction = "up",
    action = function()
        hl.exec_cmd("qs -c overview ipc call overview open")
    end,
})
hl.gesture({
    fingers = 4,
    direction = "down",
    action = function()
        hl.exec_cmd("qs -c overview ipc call overview close")
    end,
})
