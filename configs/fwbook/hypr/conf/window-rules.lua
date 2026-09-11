-- =========================
-- Window Rules
-- =========================
-- Rounding/clip is handled globally in general.lua (decoration.rounding = 12),
-- mirroring the niri window-rule. Below: float the small control/dialog
-- utilities so they don't tile.

hl.window_rule({
    name = "float-pavucontrol",
    match = { class = "org.pulseaudio.pavucontrol" },
    float = true,
})
hl.window_rule({
    name = "float-hyprland-share-picker",
    match = { title = "Select what to share" },
    float = true,
    stay_focused = true,
})
hl.window_rule({
    name = "float-blueman",
    match = { class = "^(blueman-manager)$" },
    float = true,
})
hl.window_rule({
    name = "float-calculator",
    match = { class = "^(org.gnome.Calculator)$" },
    float = true,
})
hl.window_rule({
    name = "float-portal-gtk",
    match = { class = "^(xdg-desktop-portal-gtk)$" },
    float = true,
})
hl.window_rule({
    name = "float-open-file",
    match = { title = "^(Open File)$" },
    float = true,
})
hl.window_rule({
    name = "float-save-file",
    match = { title = "^(Save File)$" },
    float = true,
})
hl.window_rule({
    match = { initial_title = "Slack - Huddle Preview" },
    float = true,
    name = "float-slack-huddle",
})
hl.window_rule({
    match = { class = "com.gabm.satty" },
    float = true,
    name = "float-satty",
})
hl.window_rule({
    match = { class = "dev.noctalia.Noctalia" },
    float = true,
    name = "float-noctalia",
    center = true,
    size = { "(monitor_w*0.5)", "(monitor_h*0.9)" },
})
hl.window_rule({
    match = { float = true },
    name = "float-style",
    no_screen_share = true,
    xray = true,
})
