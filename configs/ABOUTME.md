# configs/

Application configuration files that are symlinked into `~/.config/` via
`system.userActivationScripts` (using `skygUtils.makeHyperlinkScriptToConfigs`
from `modules/skyg-utils.nix`).

## Contents

| Path | Description |
|---|---|
| `niri/` | Niri Wayland compositor config |
| `hypr/` | Hyprland compositor config |
| `hyprpanel/` | HyprPanel bar/widget config |
| `extra.nu` | Extra NuShell config sourced at shell startup |
| `fwbook.knsv` | fwbook-specific Kanshi display profile |
| `libinput-gestures.conf` | Touchpad gesture bindings |

## Notes

- Changes here take effect on next login or when the activation script runs
- These are **not** NixOS options — they are plain config files managed as repo content
- The symlink mechanism is defined in `modules/skyg-utils.nix`
