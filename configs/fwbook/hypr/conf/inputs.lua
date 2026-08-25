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
            ["tap-to-click"] = true,
            disable_while_typing = true,
        },
    },
})

-- Three-finger horizontal swipe to move across workspaces (niri-like).
hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })
