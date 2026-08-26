-- =========================
-- Input
-- =========================
-- Mirrors configs/niri/shared/general.kdl (touchpad tap + natural scroll)
-- and kb_layout = us. `tap-to-click` is hyphenated in Hyprland, so it uses
-- bracket-key notation.

hl.config({
    input = {
        kb_layout = "us",
        follow_mouse = 1,

        touchpad = {
            natural_scroll = true,
            -- ["tap-to-click"] = true,
            disable_while_typing = true,
        },
    },
})

-- Match niri's touchpad axes: 3-finger horizontal scrolls through columns
-- (scroll_move drives the scrolling-layout tape), vertical switches workspaces.
hl.gesture({ fingers = 3, direction = "horizontal", action = "scroll_move" })
hl.gesture({ fingers = 3, direction = "vertical",   action = "workspace" })

-- niri moved a whole workspace to another monitor via Mod + touchpad scroll.
-- Hyprland gestures take a `mods` mask, so mirror that with Mod + 3-finger
-- swipes. Directions mirror niri's binds (swipe up -> monitor down, etc.);
-- flip the monitor letters if the axis feels reversed on your hardware.
hl.gesture({ fingers = 3, direction = "up",    mods = "SUPER", action = function() hl.exec_cmd("hyprctl dispatch movecurrentworkspacetomonitor d") end })
hl.gesture({ fingers = 3, direction = "down",  mods = "SUPER", action = function() hl.exec_cmd("hyprctl dispatch movecurrentworkspacetomonitor u") end })
hl.gesture({ fingers = 3, direction = "left",  mods = "SUPER", action = function() hl.exec_cmd("hyprctl dispatch movecurrentworkspacetomonitor r") end })
hl.gesture({ fingers = 3, direction = "right", mods = "SUPER", action = function() hl.exec_cmd("hyprctl dispatch movecurrentworkspacetomonitor l") end })
