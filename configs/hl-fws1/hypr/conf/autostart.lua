-- =========================
-- Autostart
-- =========================
hl.on("hyprland.start", function()
    hl.exec_cmd("setpriv --ambient-caps -all -- hypridle")
end)
