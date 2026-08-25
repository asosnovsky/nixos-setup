-- =========================
-- Monitors
-- =========================
-- Translated from configs/niri/shared/outputs.kdl.

-- Laptop internal panel
hl.monitor({ output = "eDP-1", mode = "2256x1504@60", position = "859x1080", scale = 1.5 })

-- Work monitor (ASUS VE278)
hl.monitor({ output = "desc:Ancor Communications Inc ASUS VE278 E5LMTF016849", mode = "1920x1080@60", position = "1027x0", scale = 1 })

-- Assorted external displays
hl.monitor({ output = "DP-9", mode = "1920x1080@74.97", position = "0x0", scale = 1 })
hl.monitor({ output = "desc:Samsung Electric Company S22R35x H4TR604392", mode = "1920x1080@60", position = "106x0", scale = 1 })
hl.monitor({ output = "DP-10", mode = "1920x1080@74.97", position = "1920x0", scale = 1 })
hl.monitor({ output = "desc:Samsung Electric Company S22R35x H4TR503886", mode = "1920x1080@60", position = "2026x0", scale = 1 })
hl.monitor({ output = "desc:PNP(GWD) ARZOPA", mode = "1920x1080@60", position = "2860x1080", scale = 1 })
hl.monitor({ output = "DP-2", mode = "1920x1080@60", position = "3115x1504", scale = 1 })
hl.monitor({ output = "desc:Dell Inc. DELL SE3223Q 1WDWKK3", mode = "preferred", position = "4780x0", scale = 2 })
hl.monitor({ output = "desc:Dell Inc. DELL SE3223Q 1TRXKK3", mode = "preferred", position = "6700x0", scale = 2 })

-- Fallback for anything not explicitly configured above
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = "auto" })
