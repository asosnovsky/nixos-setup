import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

// Scrolling overview for Hyprland — vertical stack of workspace rows on the
// browsed monitor, each row a horizontal strip of that workspace's windows.
// Toggle with `qs -c overview ipc call overview <toggle|open|close>`; wired
// to Mod+Tab and a 4-finger swipe in the Hyprland config.
//
// Deliberately a single window, anchored once (per open) to whichever
// monitor was actually focused when the overview opened, and never moved
// after that — a PanelWindow's HyprlandFocusGrab requires Hyprland's real
// seat focus to follow it, so a per-monitor-window design (one overlay per
// screen, switching which one is visible) would force a real focus/cursor
// jump every time you browsed to another monitor. Browsing (M / number keys
// / the monitor bar) instead just changes which monitor's workspace data
// this one fixed window displays; only activating a window (Enter/click)
// dispatches a real Hyprland focus change.
ShellRoot {
    id: shell

    property bool overviewOpen: false
    property string browsedMonitor: ""
    property var anchorScreen: null

    onOverviewOpenChanged: {
        if (shell.overviewOpen) {
            const mon = Hyprland.focusedMonitor;
            shell.browsedMonitor = mon ? mon.name : "";
            shell.anchorScreen = Quickshell.screens.find(s => mon && s.name === mon.name) ?? Quickshell.screens[0];
        }
    }

    IpcHandler {
        target: "overview"

        function toggle(): void {
            shell.overviewOpen = !shell.overviewOpen;
        }
        function open(): void {
            shell.overviewOpen = true;
        }
        function close(): void {
            shell.overviewOpen = false;
        }
    }

    OverviewWindow {
        screen: shell.anchorScreen
        shellOpen: shell.overviewOpen
        browsedMonitor: shell.browsedMonitor
        onRequestClose: shell.overviewOpen = false
        onRequestBrowseMonitor: name => shell.browsedMonitor = name
    }
}
