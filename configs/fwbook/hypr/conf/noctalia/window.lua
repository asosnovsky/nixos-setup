-- =========================
-- Noctalia window rule
-- =========================
-- Moved out of conf/window-rules.lua.
hl.window_rule({
    match = { class = "dev.noctalia.Noctalia" },
    float = true,
    name = "float-noctalia",
    center = true,
    size = { "(monitor_w*0.5)", "(monitor_h*0.9)" },
})
