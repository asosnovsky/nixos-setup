require("conf/cec")

-- =========================
-- Autostart
-- =========================
hl.on("hyprland.start", function()
    hl.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 100%")
    hl.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ 0")
    Cec.wake_and_switch()
end)
