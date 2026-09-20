-- =========================
-- Autostart
-- =========================
local function autostart()
    hl.exec_cmd("setpriv --ambient-caps -all -- noctalia")
    hl.exec_cmd("setpriv --ambient-caps -all -- qs -c overview")
end
hl.on("hyprland.start", autostart)
hl.bind("SUPER + SHIFT + A", autostart)
