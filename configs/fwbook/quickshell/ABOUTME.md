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

- **Model:** the browsed monitor's workspaces are vertical rows, each row a
  horizontal strip of that workspace's windows (columns), sorted by x-position
  to match the Hyprland `scrolling` layout's tape order.
- **Controls:** Arrow keys move the selection (Left/Right = window in the row,
  Up/Down = workspace row), a two-finger trackpad swipe does the same
  (vertical = workspace row, horizontal = window in the row), Enter focuses
  the selection and closes, Esc
  cancels, `M` cycles to the next monitor's overview, number keys 1-9 jump
  straight to the Nth monitor (sorted by Hyprland's monitor id) — also
  clickable via the monitor bar at the top of the screen. Hovering a window
  card also recenters the carousel on it (selection-only, doesn't
  focus/close). No drag/resize.
- **Monitor browsing vs. real focus:** a single overlay window, anchored once
  (per open) to whichever monitor was actually focused when the overview
  opened, and never moved after that. Switching monitors while browsing (M /
  number keys / the monitor bar) only updates local UI state
  (`shell.browsedMonitor` in `shell.qml`) that changes which monitor's
  workspace data this one fixed window displays — it never touches Hyprland's
  real focused monitor. This isn't just a style choice: a `PanelWindow`'s
  `HyprlandFocusGrab` requires Hyprland's real seat focus to follow the
  window that holds it, so a one-overlay-per-screen design (switching which
  screen's overlay is visible) would force a real focus/cursor jump to
  whichever monitor you browsed to, every time. Only activating a window or
  workspace (Enter/click) dispatches a real Hyprland focus change.
- **Previews:** live via `Quickshell.Wayland.ScreencopyView`, capturing each
  window's `HyprlandToplevel.wayland` handle. Capture only runs while the
  overview is visible (`live` is bound to the window's visibility).
- **Focus dispatch:** this Hyprland build's `hyprctl dispatch <name> <args>`
  no longer accepts classic freeform dispatch text at all — every request is
  evaluated as Lua (`hl.dispatch(<text>)`), so the text must already be a
  valid `hl.dsp.*` call. Verified forms: `hl.dsp.focus({workspace = N})`,
  `hl.dsp.focus({window = "address:0x..."})`, `hl.dsp.focus({monitor = "name"})`
  — sent via `Quickshell.execDetached(["hyprctl", "dispatch", ...])` since
  `Hyprland.dispatch()` hits the exact same broken classic-syntax path.

### Files

```
overview/
├── shell.qml            # ShellRoot: IpcHandler (target "overview": toggle/open/close),
│                         # sets browsedMonitor + anchorScreen on open, owns the single
│                         # OverviewWindow instance
├── OverviewWindow.qml    # the one PanelWindow (layer-shell overlay), anchored to
│                         # anchorScreen for the whole open session; builds the browsed
│                         # monitor's workspace/window model from Quickshell.Hyprland,
│                         # owns selection state, key handling, and HyprlandFocusGrab
├── MonitorBar.qml        # mini-map of clickable per-monitor pills, positioned AND sized
│                         # proportionally to each monitor's real x/y/resolution (like a
│                         # display-arrangement UI); highlights browsedMonitor; each pill
│                         # shows that monitor's "workspaces/windows" count
├── WorkspaceRow.qml      # one workspace = carousel Row of WindowCards + label
├── WindowCard.qml        # live ScreencopyView preview + icon/title footer + selection ring
└── Theme.qml             # plain QtObject with colors/sizes/carousel tuning, instantiated
                          # once per OverviewWindow and prop-drilled down (no singleton/qmldir)
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
