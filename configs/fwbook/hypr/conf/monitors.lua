-- =========================
-- Monitors
-- =========================
-- Laptop internal panel
hl.monitor({
    output = "eDP-1",
    mode = "2256x1504@60",
    position = "0x0",
    scale = 1.57,
})

-- Home Office
hl.monitor({
    output = "desc:Samsung Electric Company S22R35x H4TR604392",
    mode = "1920x1080@60",
    position = "-1128x-1080",
    scale = 1,
})
hl.monitor({
    output = "desc:Samsung Electric Company S22R35x H4TR503886",
    mode = "1920x1080@60",
    position = "792x-1080",
    scale = 1,
})

-- Fallback for anything not explicitly configured above
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = "auto" })
