import Quickshell
import Quickshell.Io

// Scrolling overview for Hyprland — vertical stack of workspace rows on the
// current monitor, each row a horizontal strip of that workspace's windows.
// Toggle with `qs -c overview ipc call overview <toggle|open|close>`; wired
// to Mod+Tab and a 4-finger swipe in the Hyprland config.
ShellRoot {
    id: shell

    property bool overviewOpen: false

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

    Variants {
        model: Quickshell.screens

        OverviewWindow {
            required property var modelData
            screen: modelData
            shellOpen: shell.overviewOpen
            onRequestClose: shell.overviewOpen = false
        }
    }
}
