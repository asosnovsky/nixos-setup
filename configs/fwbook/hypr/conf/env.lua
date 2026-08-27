-- =========================
-- Environment
-- =========================
-- Mirrors the environment block in configs/niri/shared/general.kdl.

hl.env("XCURSOR_SIZE", "24")
hl.env("XCURSOR_THEME", "Adwaita")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_THEME", "")
-- No HYPRCURSOR_THEME set: no hyprcursor themes are installed, so Hyprland
-- falls back to XCursor (XCURSOR_THEME) rather than showing its built-in default.
hl.env("NIXOS_OZONE_WL", "1")
hl.env("QT_QPA_PLATFORM", "wayland")
hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1")
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")
