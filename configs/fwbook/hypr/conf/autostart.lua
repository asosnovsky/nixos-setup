-- =========================
-- Autostart
-- =========================
-- Launched via UWSM (`uwsm app --`) so processes land in the correct
-- systemd scope for the graphical session.

hl.on("hyprland.start", function()
    -- noctalia shell (bar / launcher / control center / notifications)
    hl.exec_cmd("uwsm app -- noctalia-shell")
    -- Idle management
    hl.exec_cmd("uwsm app -- hypridle")
end)
