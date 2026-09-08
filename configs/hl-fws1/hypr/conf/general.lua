-- =========================
-- General / Layout
-- =========================
hl.config({
    general = {
        gaps_in = 0,
        gaps_out = 1,
        border_size = 1,
        layout = "scrolling",
        resize_on_border = true,
    },

    decoration = {
        rounding = 12,
        active_opacity = 1.0,
        inactive_opacity = 0.9,
    },

    scrolling = {
        column_width = 1,
        fullscreen_on_one_column = true,
        focus_fit_method = 0,
        follow_focus = true,
        explicit_column_widths = "0.5, 1.0",
    },

    cursor = {
        sync_gsettings_theme = true,
        enable_hyprcursor = false,
    },

    misc = {
        disable_hyprland_logo = true,
        focus_on_activate = true,
    },
})
