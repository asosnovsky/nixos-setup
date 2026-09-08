-- =========================
-- Monitors
-- =========================
-- hl-pi1 is a headless-ish clock box. Fallback catches whatever display is
-- attached (HDMI/DSI), preferred mode, auto position/scale.
hl.monitor({
    output = "",
    mode = "preferred",
    position = "auto",
    scale = "auto",
})
