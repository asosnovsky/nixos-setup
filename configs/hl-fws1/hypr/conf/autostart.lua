require("conf/cec")

-- =========================
-- Autostart
-- =========================
hl.on("hyprland.start", function()
    hl.exec_cmd("setpriv --ambient-caps -all -- hypridle")
    Cec.wake_and_switch()
end)
