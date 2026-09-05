-- =========================
-- Window Rules
-- =========================
-- Float small control/dialog utilities so they don't tile in the console layout.
hl.window_rule({ name = "float-pavucontrol", match = { class = "^(pavucontrol)$" }, float = true })
hl.window_rule({ name = "float-blueman", match = { class = "^(blueman-manager)$" }, float = true })
hl.window_rule({ name = "float-open-file", match = { title = "^(Open File)$" }, float = true })
hl.window_rule({ name = "float-save-file", match = { title = "^(Save File)$" }, float = true })
