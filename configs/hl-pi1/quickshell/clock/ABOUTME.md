# configs/hl-pi1/quickshell/clock/

Standalone Quickshell config for `hl-pi1` — the entire desktop. It is symlinked
to `~/.config/quickshell/clock` by the `skyg.nixos.desktop.tiler.quickshell`
module and launched with `qs -c clock` from the Hyprland autostart
(`configs/hl-pi1/hypr/conf/autostart.lua`). Because `hl-pi1` auto-logs into
Hyprland, this clock is what fills the screen on boot.

## What it shows

A single full-screen `PanelWindow` on the **Background** layer (so it sits
behind any tiled windows and effectively *is* the desktop background):

- **Left:** a big digital `HH:mm:ss` clock (thin monospace), with the long date
  (`Month D, YYYY`) beneath it.
- **Right:** a simple current-month calendar — a weekday header row (Sun-first)
  and a 7-column day grid, with today outlined in the accent color.
- **Background:** solid black.

## Files

| Path | Description |
|---|---|
| `shell.qml` | `ShellRoot` that instantiates the `ClockPanel` |
| `ClockPanel.qml` | The full-screen window: clock (left) + calendar (right), plus the timers that tick the clock and roll the calendar over at midnight |
| `CalendarCell.qml` | One day cell in the calendar grid (blank spacer for leading days, today outlined) |
| `Theme.qml` | Colors, fonts, and calendar sizing |

## Notes

- The clock ticks once a second, re-synced to the second boundary.
- A minute timer checks whether the day/month has rolled over and refreshes the
  date string, month header, and day grid (so "today" stays correct across
  midnight and month boundaries). The `refreshCount` bump forces the day-grid
  `Repeater` model to re-evaluate.
- Same-directory `.qml` files are visible as types automatically (no `qmldir`).

## Testing without a rebuild

```
qs -p ~/nixos-setup/configs/hl-pi1/quickshell/clock
```