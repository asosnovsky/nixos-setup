-- =========================
-- Hyprgrass (Touchpad Gestures)
-- =========================
-- Hyprgrass plugin configuration for advanced touchpad gesture support.
-- Handles swipes, taps, and other multi-finger gestures on the touchpad.
-- Documentation: https://github.com/horriblename/hyprgrass

hl.config({
    plugin = {
        hyprgrass = {
            -- Bind gestures to workspace switching (4-finger swipes)
            bind = {
                "SUPER, swipe:4:left, workspace, +1",
                "SUPER, swipe:4:right, workspace, -1",
                
                -- Hold modifier + gesture for special actions
                "ALT, swipe:4:up, exec, rofi -show",
                "ALT, swipe:4:down, exec, rofi -show window",
            },
            
            -- Bind movements (e.g., drag to move windows)
            bindm = {
                -- 3-finger drag to move windows (alternative to Super+drag)
                "SUPER, swipe:3:left, movewindow, l",
                "SUPER, swipe:3:right, movewindow, r",
                "SUPER, swipe:3:up, movewindow, u",
                "SUPER, swipe:3:down, movewindow, d",
            },
            
            -- Sensitivity and behavior settings
            sensitivity = 4.0,
            long_press_delay = 400,
            
            -- Gesture deadzone (in pixels)
            edges = {
                top = 10,
                bottom = 10,
                left = 10,
                right = 10,
            },
        }
    }
})
