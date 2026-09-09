-- =========================
-- Autostart
-- =========================
hl.on("hyprland.start", function()
    hl.exec_cmd("setpriv --ambient-caps -all -- noctalia")
    hl.exec_cmd("steam -tenfoot")
end)
