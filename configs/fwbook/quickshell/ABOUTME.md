# configs/fwbook/quickshell/

Host-specific Quickshell configs for `fwbook`. Symlinked to `~/.config/quickshell`
by the `skyg.nixos.desktop.tiler.quickshell` module, which defaults its
`configName` to the machine hostName (`configs/${hostName}/quickshell`).

Quickshell resolves each subdirectory as an independently named config, run
via `qs -c <name>` (or `qs -p <path>` for direct path testing without the
symlink). This is deliberately not part of noctalia/DMS — each `qs -c <name>`
here is its own standalone process/shell.

## overview/

A niri-like scrolling overview for Hyprland, standing in for a native overview
plugin (Hyprland has none maintained against tagged releases — see
`modules/nixos/desktop/tiler/ABOUTME.md`).

- **Model:** the current monitor's workspaces are vertical rows, each row a
  horizontal strip of that workspace's windows (columns), sorted by x-position
  to match the Hyprland `scrolling` layout's tape order.
- **Controls:** Arrow keys move the selection (Left/Right = window in the row,
  Up/Down = workspace row), Enter focuses the selection and closes, Esc
  cancels, `M` cycles to the next monitor's overview, number keys 1-9 jump
  straight to the Nth monitor (sorted by Hyprland's monitor id). Hovering a
  window card also recenters the carousel on it (selection-only, doesn't
  focus/close). No drag/resize.
- **Previews:** live via `Quickshell.Wayland.ScreencopyView`, capturing each
  window's `HyprlandToplevel.wayland` handle. Capture only runs while the
  overview is visible (`live` is bound to the window's visibility).
- **Focus dispatch:** classic `hyprctl`-style dispatcher strings
  (`"workspace " + id`, `"focuswindow address:" + addr`) via
  `Hyprland.dispatch(...)` — these work regardless of whether Hyprland's
  config is Lua or hyprlang, unlike the Lua-eval dispatch form.

### Files

```
overview/
├── shell.qml            # ShellRoot: IpcHandler (target "overview": toggle/open/close)
│                         # + Variants { model: Quickshell.screens } instantiating one
│                         # OverviewWindow per monitor
├── OverviewWindow.qml    # per-monitor PanelWindow (layer-shell overlay); builds the
│                         # workspace/window model from Quickshell.Hyprland, owns
│                         # selection state, key handling, and HyprlandFocusGrab
├── WorkspaceRow.qml      # one workspace = horizontal Row of WindowCards + label
├── WindowCard.qml        # live ScreencopyView preview + icon/title footer + selection ring
└── Theme.qml             # plain QtObject with colors/sizes, instantiated once per
                          # OverviewWindow and prop-drilled down (no singleton/qmldir)
```

`Theme.qml` and the other sibling `.qml` files are used without explicit
imports — Quickshell (like plain QML) makes same-directory files visible as
types automatically, no `qmldir` needed for single-directory configs like this
one.

### Wiring (Hyprland side, `configs/fwbook/hypr/`)

- `conf/keybindings.lua` — `Mod+Tab` runs `qs -c overview ipc call overview toggle`
- `conf/inputs.lua` — 4-finger swipe up/down open/close it (discrete gesture,
  no swipe-progress animation)
- `conf/autostart.lua` — the daemon is started via
  `setpriv --ambient-caps -all -- qs -c overview` (D-Bus calls in
  quickshell-based apps fail silently without this wrapper under this
  Hyprland/UWSM setup)

### Testing without a rebuild

Since `~/.config/quickshell` is a symlink into this repo, edits are live.
Test directly by path before relying on the installed symlink:

```
qs -p ~/nixos-setup/configs/fwbook/quickshell/overview
qs -p ~/nixos-setup/configs/fwbook/quickshell/overview ipc call overview toggle
```
