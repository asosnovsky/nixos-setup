-- =========================
-- Autostart
-- =========================
hl.on("hyprland.start", function()
    hl.exec_cmd("setpriv --ambient-caps -all -- noctalia")
    hl.exec_cmd("setpriv --ambient-caps -all -- qs -c overview")
    hl.exec_cmd("setpriv --ambient-caps -all -- hypridle")
end)
