-- =========================
-- General / Layout
-- =========================
hl.config({
    general = {
        gaps_in = 0,
        gaps_out = 0,
        border_size = 2,
        layout = "scrolling",
        resize_on_border = true,

        col = {
            active_border = "rgb(00e5ff)",
            inactive_border = "rgb(6a5acd)",
        },
    },

    decoration = {
        rounding = 8,
        active_opacity = 1.0,
        inactive_opacity = 0.9,
    },

    scrolling = {
        fullscreen_on_one_column = true,
        follow_focus = true,
        focus_fit_method = 1,
    },

    cursor = {
        sync_gsettings_theme = true,
        enable_hyprcursor = true,
    },

    misc = {
        disable_hyprland_logo = true,
        focus_on_activate = true,
    },
})
