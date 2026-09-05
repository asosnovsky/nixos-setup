-- =========================
-- Autostart
-- =========================
hl.on("hyprland.start", function()
    -- Lounge console: drop straight into Steam Big Picture.
    hl.exec_cmd("steam -tenfoot")
end)
