# configs/

Dotfiles and app configs that are symlinked into the home dir by activation
scripts. This is how user-level config is managed here (no Home Manager).

- `shared/` is for every host; `<hostName>/` is for one machine.
- New links are declared with `skyg.configLinks.links.<name>` (`source` under
  `configs/`, `target` under the home dir) — see
  `modules/nixos/common/config-links.nix`.
- The desktop modules (hyprland, niri, noctalia, quickshell, omarchy) link
  `~/.config/<type>` -> `configs/<hostName>/<type>` with the older
  `skygUtils.makeHyperlinkScriptToConfigs` helper and their own `configLink`
  options.

## Contents

| Path                 | Description                                                                                                                                           |
| -------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------- |
| `shared/zsh/zshrc`   | zsh extras (carapace, long-command notify, host functions); linked to `~/.zshrc` for the user and root                                               |
| `shared/starship.toml` | Starship prompt settings; linked to `~/.config/starship.toml`                                                                                     |
| `shared/git/config`  | Git settings and aliases (name/email come from `/etc/gitconfig`); linked to `~/.config/git/config`                                                   |
| `shared/zellij/`     | Zellij `config.kdl`; linked to `~/.config/zellij/config.kdl`                                                                                          |
| `shared/nushell/`    | Nushell `config.nu` (starship, carapace, direnv, aliases); linked to `~/.config/nushell/config.nu`                                                   |
| `shared/theme/`      | Fixed gruvbox GTK css/settings, Kvantum theme and qt5ct/qt6ct config; linked read-only by `modules/nixos/desktop/stylix`                              |
| `fwbook/zsh/`        | Extra zsh functions for `fwbook`; linked to `~/.config/zsh` and sourced by `shared/zsh/zshrc`                                                         |
| `fwbook/mimeapps.list` | Default apps for `fwbook`; linked read-only to `~/.config/mimeapps.list` (edit, then rebuild)                                                     |
| `fwbook/niri/`       | Niri config for `fwbook`; linked to `~/.config/niri` by the `skyg.nixos.desktop.tiler.niri` module (mirrors the hyprland pattern)                     |
| `fwbook/hypr/`       | Hyprland config for `fwbook` (scrolling layout; Omarchy/nixarchy shell — noctalia binds+rules parked in `conf/noctalia/`); linked to `~/.config/hypr` |
| `fwbook/omarchy/`    | Omarchy (nixarchy) shell config for `fwbook` (`shell.json`, plugins, backgrounds); linked to `~/.config/omarchy` by `hosts/fwbook/packages.nix`       |
| `hl-fwdesk/hypr/`    | Hyprland config for `hl-fwdesk` (Steam console); **baked into the build** via `mountAsSource`, linked to `~/.config/hypr`                             |
| `hl-pi1/hypr/`       | Hyprland config for `hl-pi1` (clock box); linked to `~/.config/hypr`                                                                                  |
| `hl-fws1/hypr/`      | Hyprland config for `hl-fws1` (remote slim desktop); **baked into the build** via `mountAsSource`, linked to `~/.config/hypr`                         |
| `hl-pi1/quickshell/` | Quickshell configs for `hl-pi1` (full-screen clock + calendar); linked to `~/.config/quickshell`                                                      |
| `fwbook/quickshell/` | Quickshell configs for `fwbook` (scrolling overview); linked to `~/.config/quickshell`                                                                |
| `extra.nu` | Extra NuShell helpers |
| `hypr-types/hl.lua` | Shared EmmyLua type stubs for the `hl` global; each host's Hyprland `.luarc.json` points here via `workspace.library` |
| `pki/` | Public certs of the lab internal CA (`lab-ca.crt` + issued leaves), managed by `skyg ca`; **not** symlinked to `~/.config` — see `pki/ABOUTME.md` |

## Notes

- These are **not** NixOS options — they are plain config files managed as repo content
- `skyg.configLinks` links point at a read-only store copy by default, so edits
  need a rebuild. Hosts with the repo at `~/nixos-setup` set
  `skyg.configLinks.live = true` (e.g. `fwbook`): links then point at the
  checkout and edits apply at once. Links marked `baked = true` stay read-only.
- Links are (re)made at login and on every switch; a real file in the way is
  moved to `<path>.backup.<timestamp>`
- The link script itself is `makeLinkScript` in `modules/skyg-utils.nix`
- Hosts can embed their config in the build by setting
  `configLink.mountAsSource = true`; the dir is then read from the flake's
  store path (`skyg.rootDir`) instead of the live `~/nixos-setup/configs`
  checkout. See `modules/nixos/desktop/tiler/hyprland.nix`.
