-- =========================
-- Autostart
-- =========================
local function autostart()
    hl.exec_cmd("setpriv --ambient-caps -all -- noctalia")
    hl.exec_cmd("setpriv --ambient-caps -all -- qs -c overview")
    hl.exec_cmd("setpriv --ambient-caps -all -- hypridle")
end
hl.on("hyprland.start", autostart)
hl.bind("SUPER + SHIFT + A", autostart)
