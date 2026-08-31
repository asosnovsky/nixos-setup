import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

PanelWindow {
    id: root

    required property bool shellOpen
    required property string browsedMonitor
    signal requestClose()
    signal requestBrowseMonitor(string name)

    visible: root.shellOpen

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

    // Workspace rows for the browsed monitor, top-to-bottom by workspace id.
    // Special (scratchpad) workspaces have negative ids and are excluded.
    readonly property var rows: {
        if (!root.browsedMonitor || !Hyprland.workspaces) return [];
        const workspaces = Hyprland.workspaces.values
            .filter(ws => ws && ws.id > 0 && ws.monitor && ws.monitor.name === root.browsedMonitor)
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

    // Advances which monitor's overview is being browsed (see shell.qml) —
    // purely local UI state, doesn't touch Hyprland's real focused monitor.
    function cycleMonitor() {
        const mons = root.sortedMonitors;
        if (mons.length === 0) return;
        const curIdx = Math.max(0, mons.findIndex(m => m.name === root.browsedMonitor));
        const mon = mons[(curIdx + 1) % mons.length];
        root.requestBrowseMonitor(mon.name);
    }

    readonly property var sortedMonitors: Hyprland.monitors ? Hyprland.monitors.values.slice().sort((a, b) => a.id - b.id) : []

    // Per-monitor {workspaces, windows} totals for the monitor bar pills.
    readonly property var monitorStats: root.sortedMonitors.map(mon => {
        const workspaces = Hyprland.workspaces ? Hyprland.workspaces.values
            .filter(ws => ws && ws.id > 0 && ws.monitor && ws.monitor.name === mon.name) : [];
        const windows = workspaces.reduce((n, ws) => n + (ws.toplevels ? ws.toplevels.values.length : 0), 0);
        return { workspaces: workspaces.length, windows: windows };
    })

    // Jump straight to the Nth monitor's overview (0-based), bound to number
    // keys 1-9 and the monitor bar.
    function focusMonitorByIndex(i) {
        const mon = root.sortedMonitors[i];
        if (!mon) return;
        root.requestBrowseMonitor(mon.name);
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

        // Hovering a card recenters the carousel, which can slide a
        // different card under an otherwise-stationary cursor and retrigger
        // hover on it ("combo hover"). A pure movement-distance check isn't
        // enough — ordinary mouse/trackpad jitter (a few px) clears a small
        // threshold on its own. So: hard-lock all hover triggers for the
        // duration of the recentering animation (nothing can retrigger while
        // cards are still sliding), and additionally require the cursor to
        // have moved well past jitter range since the last accepted trigger.
        HoverHandler {
            id: mouseTracker
        }
        property point lastHoverAcceptPos: Qt.point(-1, -1)
        property bool hoverLocked: false
        Timer {
            id: hoverLockTimer
            interval: root.theme.carouselDuration
            onTriggered: focusScope.hoverLocked = false
        }
        function shouldAcceptHover() {
            if (focusScope.hoverLocked) return false;
            const cur = mouseTracker.point.position;
            const dx = cur.x - focusScope.lastHoverAcceptPos.x;
            const dy = cur.y - focusScope.lastHoverAcceptPos.y;
            if ((dx * dx + dy * dy) <= 1600) return false; // 40px
            focusScope.lastHoverAcceptPos = cur;
            focusScope.hoverLocked = true;
            hoverLockTimer.restart();
            return true;
        }

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
            case Qt.Key_M:
                root.cycleMonitor();
                break;
            case Qt.Key_1:
            case Qt.Key_2:
            case Qt.Key_3:
            case Qt.Key_4:
            case Qt.Key_5:
            case Qt.Key_6:
            case Qt.Key_7:
            case Qt.Key_8:
            case Qt.Key_9:
                root.focusMonitorByIndex(event.key - Qt.Key_1);
                break;
            default:
                return;
            }
            event.accepted = true;
        }

        MonitorBar {
            anchors.top: parent.top
            anchors.topMargin: 24
            anchors.horizontalCenter: parent.horizontalCenter
            theme: root.theme
            monitors: root.sortedMonitors
            monitorStats: root.monitorStats
            focusedMonitorName: root.browsedMonitor
            onMonitorClicked: index => root.focusMonitorByIndex(index)
        }

        Item {
            anchors.fill: parent

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

                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.verticalCenterOffset: (index - root.selectedRow) * root.theme.carouselStepY
                    opacity: 1 - Math.min(Math.abs(index - root.selectedRow) * root.theme.carouselFadeStep, root.theme.carouselMaxFade)
                    scale: 1 - Math.min(Math.abs(index - root.selectedRow) * root.theme.carouselScaleStep, root.theme.carouselMaxScaleReduction)

                    Behavior on anchors.verticalCenterOffset {
                        NumberAnimation { duration: root.theme.carouselDuration; easing.type: Easing.OutCubic }
                    }
                    Behavior on opacity {
                        NumberAnimation { duration: root.theme.carouselDuration }
                    }
                    Behavior on scale {
                        NumberAnimation { duration: root.theme.carouselDuration }
                    }

                    onCardClicked: colIndex => {
                        root.selectedRow = index;
                        root.selectedCol = colIndex;
                        root.activateSelection();
                    }
                    onCardHovered: colIndex => {
                        if (!focusScope.shouldAcceptHover()) return;
                        root.selectedRow = index;
                        root.selectedCol = colIndex;
                    }
                }
            }
        }
    }
}
