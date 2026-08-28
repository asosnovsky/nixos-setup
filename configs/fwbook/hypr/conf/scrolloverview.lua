-- =========================
-- ScrollOverview (niri-like overview)
-- =========================
-- ScrollOverview plugin: an overview just like niri's, based on the
-- scroll-overview branch of hyprexpo. Docs:
-- https://github.com/yayuuu/hyprland-scroll-overview

-- environment.systemPackages only puts libscrolloverview.so on disk -- Hyprland
-- doesn't load plugins on its own. SCROLLOVERVIEW_SO is set in
-- modules/nixos/desktop/tiler/hyprland.nix (sessionVariables) to the resolved
-- store path, since that path changes on every flake update. Must run before
-- anything below references plugin.scrolloverview config keys or
-- hl.plugin.scrolloverview, both of which only exist once the plugin is loaded.
hl.plugin.load(os.getenv("SCROLLOVERVIEW_SO"))

hl.config({
    plugin = {
        scrolloverview = {},
    },
})

-- Toggle the overview with Mod+g (niri's toggle-overview lives on Mod+Tab in
-- conf/keybindings.lua, which now calls into this plugin too).
hl.bind("SUPER + g", function()
    hl.plugin.scrolloverview.overview("toggle all")
end)
