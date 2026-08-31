import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

PanelWindow {
    id: root

    required property bool shellOpen
    signal requestClose()

    readonly property var monitor: Hyprland.monitorFor(root.screen)
    readonly property bool monitorFocused: monitor && Hyprland.focusedMonitor && monitor.id === Hyprland.focusedMonitor.id
    visible: root.shellOpen && root.monitorFocused

    color: "transparent"

    WlrLayershell.namespace: "quickshell:overview"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.exclusiveZone: -1
    WlrLayershell.keyboardFocus: root.visible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    anchors {
        top: true
        left: true
        right: true
        bottom: true
    }

    property Theme theme: Theme {}

    // Sorts a workspace's toplevels by x-position so card order matches the
    // scrolling layout's column order.
    function sortedToplevels(ws) {
        const list = (ws && ws.toplevels) ? ws.toplevels.values.slice() : [];
        return list.sort((a, b) => {
            const ax = a?.lastIpcObject?.at?.[0] ?? 0;
            const bx = b?.lastIpcObject?.at?.[0] ?? 0;
            return ax - bx;
        });
    }

    // Workspace rows for this monitor, top-to-bottom by workspace id. Special
    // (scratchpad) workspaces have negative ids and are excluded.
    readonly property var rows: {
        const mon = root.monitor;
        if (!mon || !Hyprland.workspaces) return [];
        const workspaces = Hyprland.workspaces.values
            .filter(ws => ws && ws.id > 0 && ws.monitor && ws.monitor.name === mon.name)
            .sort((a, b) => a.id - b.id);
        return workspaces.map(ws => ({ workspace: ws, toplevels: root.sortedToplevels(ws) }));
    }

    property int selectedRow: 0
    property int selectedCol: 0

    function clampSelection() {
        if (root.rows.length === 0) {
            root.selectedRow = 0;
            root.selectedCol = 0;
            return;
        }
        if (root.selectedRow >= root.rows.length) root.selectedRow = root.rows.length - 1;
        if (root.selectedRow < 0) root.selectedRow = 0;
        const count = root.rows[root.selectedRow].toplevels.length;
        if (root.selectedCol >= count) root.selectedCol = Math.max(0, count - 1);
        if (root.selectedCol < 0) root.selectedCol = 0;
    }

    // Reset the selection to the active workspace/window whenever the
    // overview opens.
    function resetSelection() {
        const activeRowIndex = root.rows.findIndex(r => r.workspace.active);
        root.selectedRow = activeRowIndex >= 0 ? activeRowIndex : 0;
        const row = root.rows[root.selectedRow];
        const activeColIndex = row ? row.toplevels.findIndex(tl => tl.activated) : -1;
        root.selectedCol = activeColIndex >= 0 ? activeColIndex : 0;
        root.clampSelection();
    }

    function moveSelection(dRow, dCol) {
        if (root.rows.length === 0) return;
        if (dRow !== 0) {
            root.selectedRow = (root.selectedRow + dRow + root.rows.length) % root.rows.length;
            root.clampSelection();
        }
        if (dCol !== 0) {
            const count = root.rows[root.selectedRow].toplevels.length;
            if (count > 0) root.selectedCol = (root.selectedCol + dCol + count) % count;
        }
    }

    // This Hyprland build no longer accepts classic freeform dispatch text
    // ("focuswindow address:0x...") at all — `hyprctl dispatch <text>` always
    // evaluates <text> as a Lua expression (`hl.dispatch(<text>)`), so the
    // text itself must already be a valid hl.dsp.* dispatcher call. Verified
    // directly against this host: `hl.dsp.focus({workspace = N})` and
    // `hl.dsp.focus({window = "address:0x..."})` both work; the classic
    // `focuswindow address:...` / `workspace N` forms both error out.
    function activateSelection() {
        const row = root.rows[root.selectedRow];
        if (!row) { root.requestClose(); return; }
        if (!row.workspace.active) {
            Quickshell.execDetached(["hyprctl", "dispatch", `hl.dsp.focus({workspace = ${row.workspace.id}})`]);
        }
        const tl = row.toplevels[root.selectedCol];
        if (tl) {
            const addr = tl.address.startsWith("0x") ? tl.address : "0x" + tl.address;
            Quickshell.execDetached(["hyprctl", "dispatch", `hl.dsp.focus({window = "address:${addr}"})`]);
        }
        root.requestClose();
    }

    onVisibleChanged: {
        if (root.visible) {
            Hyprland.refreshMonitors();
            Hyprland.refreshWorkspaces();
            Hyprland.refreshToplevels();
            root.resetSelection();
            Qt.callLater(() => focusScope.forceActiveFocus());
        }
    }

    HyprlandFocusGrab {
        windows: [root]
        active: root.visible
        onCleared: {
            if (root.visible) root.requestClose();
        }
    }

    Rectangle {
        anchors.fill: parent
        color: root.theme.backdrop

        MouseArea {
            anchors.fill: parent
            onClicked: root.requestClose()
        }
    }

    FocusScope {
        id: focusScope
        anchors.fill: parent
        focus: root.visible

        Keys.onPressed: event => {
            switch (event.key) {
            case Qt.Key_Left:
                root.moveSelection(0, -1);
                break;
            case Qt.Key_Right:
                root.moveSelection(0, 1);
                break;
            case Qt.Key_Up:
                root.moveSelection(-1, 0);
                break;
            case Qt.Key_Down:
                root.moveSelection(1, 0);
                break;
            case Qt.Key_Return:
            case Qt.Key_Enter:
                root.activateSelection();
                break;
            case Qt.Key_Escape:
                root.requestClose();
                break;
            default:
                return;
            }
            event.accepted = true;
        }

        Column {
            anchors.centerIn: parent
            spacing: root.theme.rowSpacing

            Repeater {
                model: root.rows

                WorkspaceRow {
                    required property var modelData
                    required property int index

                    theme: root.theme
                    workspace: modelData.workspace
                    toplevels: modelData.toplevels
                    selectedIndex: index === root.selectedRow ? root.selectedCol : -1
                    live: root.visible

                    onCardClicked: colIndex => {
                        root.selectedRow = index;
                        root.selectedCol = colIndex;
                        root.activateSelection();
                    }
                }
            }
        }
    }
}
