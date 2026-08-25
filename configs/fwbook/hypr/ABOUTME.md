# configs/fwbook/hypr/

Host-specific Hyprland configuration for `fwbook`. Symlinked to `~/.config/hypr`
by the `skyg.nixos.desktop.tiler.hyprland` module, which defaults its
`configName` to the machine hostName (`configs/${hostName}/hypr`).

## Why it lives here (and not configs/hypr)

The Hyprland module links `configs/<configName>/hypr` -> `~/.config/hypr`, with
`configName` defaulting to the hostName. Keeping the config under
`configs/fwbook/` lets each host own its own Hyprland tweaks (monitors, etc.)
without stepping on other machines. The old shared `configs/hypr/` (waybar +
hyprpanel) was removed when this replaced it.

## Design

- **Layout:** Hyprland's native `scrolling` layout (0.54+), no plugins required.
  This mirrors niri's scrollable-tiling model. See `hyprland.d/general.conf`.
- **Shell:** noctalia (`noctalia-shell`), autostarted in `hyprland.d/autostart.conf`.
  There is intentionally no waybar/hyprpanel here.
- **Keybinds:** `hyprland.d/keybindings.conf` mirrors `configs/niri/shared/binds.kdl`
  and `configs/niri/noctalia/binds.kdl` as closely as Hyprland allows.
- **Overview:** there is no native Hyprland overview, and no overview plugin that
  reliably builds against current Hyprland (hyprexpo was retired from the
  official plugins repo; the community fork chases `main`). `Mod+Tab` falls back
  to `cyclenext` instead of niri's `toggle-overview`.

## Files

```
hypr/
├── hyprland.conf                 # variables + sources hyprland.d/*.conf
├── screen-record.sh              # wf-recorder toggle (bound to Mod+R)
└── hyprland.d/
    ├── env.conf                  # cursor size + Wayland/Qt/Electron env hints
    ├── general.conf              # scrolling layout, gaps/border/rounding
    ├── monitors.conf             # translated from configs/niri/shared/outputs.kdl
    ├── inputs.conf               # touchpad tap + natural scroll, kb us, swipe
    ├── window-rules.conf         # float small dialogs/utilities
    ├── keybindings.conf          # niri + noctalia binds, scrolling dispatchers
    └── autostart.conf            # noctalia, hypridle (via UWSM)
```

## Bindings without a clean 1:1 niri mapping

- `Mod+Shift+H` (show-hotkey-overlay) — no native Hyprland equivalent; left commented.
- `Mod+Escape` (toggle-keyboard-shortcuts-inhibit) — no native equivalent; omitted.
- `Mod+W` (toggle-column-tabbed-display) — mapped to `togglegroup` as the nearest analog.
- `Mod+Tab` (toggle-overview) — no native overview / no buildable plugin; mapped to `cyclenext`.
- Workspace-to-monitor moves (niri used touchpad scroll) — approximated with
  `Mod + mouse wheel`.
