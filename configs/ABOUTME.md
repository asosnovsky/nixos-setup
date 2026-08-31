# configs/

Application configuration files that are symlinked into `~/.config/` via
`system.userActivationScripts` (using `skygUtils.makeHyperlinkScriptToConfigs`
from `modules/skyg-utils.nix`).

Most entries link `~/.config/<name>` -> `configs/<name>`. Some are host-scoped
and live under `configs/<hostName>/` — e.g. the Hyprland module links
`~/.config/hypr` -> `configs/<hostName>/hypr` (defaulting to the machine's
hostName). `makeHyperlinkScriptToConfigs` takes an optional `targetPath` for
these cases where the source subdir and `~/.config` target differ.

## Contents

| Path | Description |
|---|---|
| `niri/` | Niri Wayland compositor config |
| `fwbook/hypr/` | Hyprland config for `fwbook` (scrolling layout + noctalia); linked to `~/.config/hypr` |
| `fwbook/quickshell/` | Quickshell configs for `fwbook` (scrolling overview); linked to `~/.config/quickshell` |
| `extra.nu` | Extra NuShell config sourced at shell startup |
| `fwbook.knsv` | fwbook-specific Kanshi display profile |
| `libinput-gestures.conf` | Touchpad gesture bindings |

## Notes

- Changes here take effect on next login or when the activation script runs
- These are **not** NixOS options — they are plain config files managed as repo content
- The symlink mechanism is defined in `modules/skyg-utils.nix`
