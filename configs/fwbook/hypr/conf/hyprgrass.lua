-- =========================
-- Hyprgrass (Touchpad Gestures)
-- =========================
-- Hyprgrass plugin configuration for advanced touchpad gesture support.
-- Documentation: https://github.com/horriblename/hyprgrass
-- Config reference: docs/configuration.md

-- environment.systemPackages only puts libhyprgrass.so on disk -- Hyprland
-- doesn't load plugins on its own. HYPRGRASS_SO is set in
-- modules/nixos/desktop/tiler/hyprland.nix (sessionVariables) to the resolved
-- store path, since that path changes on every flake update. Must run before
-- anything below references plugin.hyprgrass config keys or hl.plugin.hyprgrass,
-- both of which only exist once the plugin is loaded.
hl.plugin.load(os.getenv("HYPRGRASS_SO"))

hl.config({
    plugin = {
        hyprgrass = {
            -- The default sensitivity is probably too low on tablet screens,
            -- I recommend turning it up to 4.0
            sensitivity = 4.0,

            -- in milliseconds
            long_press_delay = 400,

            -- resize windows by long-pressing on window borders and gaps.
            resize_on_border_long_press = true,

            -- in pixels, the distance from the edge that is considered an edge
            edge_margin = 10,
        },
    },
})

-- =========================
-- Custom gesture bindings
-- =========================

-- -- -- 4-finger swipes to switch workspaces
hl.plugin.hyprgrass.gesture({
    pattern = { kind = "swipe", fingers = 4, direction = "left" },
    action = "workspace",
})
hl.plugin.hyprgrass.gesture({
    pattern = { kind = "swipe", fingers = 4, direction = "right" },
    action = "workspace",
})

-- 3-finger tap to toggle floating
hl.plugin.hyprgrass.bind({
    pattern = { kind = "tap", fingers = 3 },
    action = hl.dsp.window.float(),
})
