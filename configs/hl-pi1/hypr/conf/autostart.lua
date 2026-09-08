-- =========================
-- Autostart
-- =========================
-- Launch the Quickshell clock as the whole desktop. `setpriv --ambient-caps
-- -all` drops capabilities inherited from the compositor; without it, D-Bus
-- calls inside quickshell-based apps fail silently.
hl.on("hyprland.start", function()
    hl.exec_cmd("setpriv --ambient-caps -all -- qs -c clock")
end)
