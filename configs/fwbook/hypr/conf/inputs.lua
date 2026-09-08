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
