-- =========================
-- Animations
-- =========================
-- niri stacks workspaces vertically (Mod+Up/Down, 3-finger vertical swipe), so
-- switch the workspace transition to a vertical slide instead of Hyprland's
-- default horizontal `slide`. Only the `workspaces` leaf is overridden;
-- workspacesIn/Out inherit it and every other animation stays on defaults.

-- hl.animation requires an explicit bezier/spring (there is no built-in
-- "default" curve name in the Lua API), so define one first.
hl.curve("wsslide", {
    type = "bezier",
    points = { { 0.05, 0.9 }, { 0.1, 1.0 } },
})


hl.animation({
    leaf = "workspaces",
    enabled = true,
    speed = 2,
    bezier = "wsslide",
    style = "slidevert",
})
