-- =========================
-- Window Rules
-- =========================
-- Float utility dialogs so they don't tile over the clock.
hl.window_rule({ name = "float-pavucontrol", match = { class = "^(pavucontrol)$" }, float = true })
hl.window_rule({ name = "float-open-file", match = { title = "^(Open File)$" }, float = true })
hl.window_rule({ name = "float-save-file", match = { title = "^(Save File)$" }, float = true })
