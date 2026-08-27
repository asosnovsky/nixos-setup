-- =========================
-- Animations
-- =========================

-- Animation to Mimic Niri's up/down slide for workspaces
hl.animation({
    leaf = "workspaces",
    enabled = true,
    speed = 2,
    bezier = "wsslide",
    style = "slidevert",
})

hl.animation({
    leaf = "windows",
    enabled = true,
    speed = 5,
    bezier = "default",
    style = "slidefade 60%",
})

hl.animation({
    leaf = "windowsMove",
    enabled = true,
    speed = 5,
    bezier = "default",
    style = "slidefade 80%",
})
