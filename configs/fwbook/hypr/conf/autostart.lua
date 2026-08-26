-- =========================
-- Autostart
-- =========================
-- Launched via UWSM (`uwsm app --`) so processes land in the correct
-- systemd scope for the graphical session.

hl.on("hyprland.start", function()
    -- noctalia shell (bar / launcher / control center / notifications)
    -- setpriv drops ambient capabilities inherited from the compositor;
    -- without it, D-Bus calls inside quickshell-based apps fail silently.
    hl.exec_cmd("setpriv --ambient-caps -all -- noctalia")
    -- Idle management
    hl.exec_cmd("setpriv --ambient-caps -all -- hypridle")
end)
