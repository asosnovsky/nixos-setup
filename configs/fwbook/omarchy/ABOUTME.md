# configs/fwbook/omarchy/

Host-specific Omarchy (nixarchy) shell config for `fwbook`.
Symlinked to `~/.config/omarchy` by `hosts/fwbook/packages.nix`
(`system.userActivationScripts.omarchyConfig`), same pattern as hypr/noctalia.

## Layout

| Path | Notes |
| --- | --- |
| `shell.json` | Bar layout, idle timings, enabled plugins. No `omarchy.system-update` widget (its 6h poll is a no-op on NixOS). |
| `shell.toml` | Font base size for the shell. |
| `defaults/` | Defaults the shell writes (e.g. `agent`). |
| `backgrounds/` | User wallpapers / live-wallpaper sources. |
| `plugins/` | **Not tracked** (gitignored). Third-party checkouts with their own `.git` so `omarchy-plugin-update` still works. `shell.json` lists enabled ids; clone/install into this dir on each machine. |

Runtime state stays under `~/.local/state/omarchy/` (clipboard, toggles, etc.) — not here.

## Plugins currently in use (local only)

| id | source |
| --- | --- |
| `tenzin.live-wallpaper` | https://github.com/yesheytenzin/live-wallpaper |
| `io.github.ehlxr.advanced-workspaces` | https://github.com/ehlxr/advanced-workspaces |

## Package wiring

Shell binary + `OMARCHY_PATH` live in `hosts/fwbook/packages.nix`.
Launch is `omarchy-launch-shell` from `configs/fwbook/hypr/conf/autostart.lua`.
No nixarchy NixOS/HM modules.
