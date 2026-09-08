import QtQuick
import Quickshell

// Full-screen Background-layer window — the entire desktop for hl-pi1.
// Big digital clock on the left, simple current-month calendar on the right.
PanelWindow {
    id: root

    color: theme.background
    visible: true

    WlrLayershell.namespace: "quickshell:clock"
    WlrLayershell.layer: WlrLayer.Background

    anchors {
        top: true
        left: true
        right: true
        bottom: true
    }

    property Theme theme: Theme {}

    // Monotonic bump used to force the calendar Repeater's model to be
    // re-evaluated (the model is a function of this value and today's date).
    property int refreshCount: 0
    property string lastDay: ""

    // ------------------------------------------------ Clock (left) ---------
    Item {
        anchors.left: parent.left
        anchors.leftMargin: parent.width * 0.12
        anchors.verticalCenter: parent.verticalCenter

        Text {
            id: timeText
            anchors.left: parent.left
            anchors.top: parent.top
            color: theme.accent
            font.family: theme.fontFamily
            font.pixelSize: theme.clockFontSize
            font.weight: Font.Thin
            text: root.hhmmss()
        }

        Text {
            id: dateText
            anchors.left: parent.left
            anchors.top: timeText.bottom
            anchors.topMargin: 24
            color: "#b3ffffff"
            font.family: theme.fontFamily
            font.pixelSize: theme.dateFontSize
            text: root.longDate()
        }
    }

    // Tick the clock every second, re-synced to the second boundary.
    Timer {
        id: clockTimer
        interval: 1000 - (new Date().getTime() % 1000)
        repeat: true
        running: true
        onTriggered: {
            timeText.text = root.hhmmss();
            clockTimer.interval = 1000 - (new Date().getTime() % 1000);
        }
    }

    // Every minute, if the day (or month) has rolled over, refresh the date
    // string, the month header, and the day grid (so "today" stays correct).
    Timer {
        id: dayTimer
        interval: 60 * 1000
        repeat: true
        running: true
        onTriggered: {
            if (root.todayKey() !== root.lastDay) {
                root.lastDay = root.todayKey();
                root.refreshDateAndCalendar();
            }
        }
        Component.onCompleted: root.lastDay = root.todayKey()
    }

    // ------------------------------------------------ calendar (right) -----
    Item {
        id: calendarView
        anchors.right: parent.right
        anchors.rightMargin: parent.width * 0.10
        anchors.verticalCenter: parent.verticalCenter

        // Month + year header.
        Text {
            id: monthHeader
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            color: theme.accent
            font.family: theme.fontFamily
            font.pixelSize: theme.headerFontSize
            text: root.calTitle()
        }

        // Weekday header row (Sunday-first), one cell below the title.
        Repeater {
            model: root.weekdayModel()
            Text {
                required property var modelData
                required property int index
                x: index * (theme.cellSize + theme.cellSpacing)
                y: monthHeader.height + 18
                width: theme.cellSize
                horizontalAlignment: Text.AlignHCenter
                color: "#80ffffff"
                font.family: theme.fontFamily
                font.pixelSize: theme.calendarFontSize
                text: modelData
            }
        }

        // 7-column day grid, Sunday-first, today highlighted.
        Repeater {
            model: root.buildCells(root.refreshCount)
            CalendarCell {
                required property var modelData
                required property int index
                x: (index % 7) * (theme.cellSize + theme.cellSpacing)
                y: monthHeader.height + 18 + (theme.cellSize + theme.cellSpacing) + Math.floor(index / 7) * (theme.cellSize + theme.cellSpacing)
                label: modelData.label
                isToday: modelData.isToday
                cellSize: theme.cellSize
                accent: theme.accent
                fontFamily: theme.fontFamily
                fontSize: theme.calendarFontSize
            }
        }
    }

    // ---- helpers ----------------------------------------------------------
    function todayKey(): string {
        const d = new Date();
        return d.getFullYear() + "-" + d.getMonth() + "-" + d.getDate();
    }

    function hhmmss(): string {
        const d = new Date();
        const hh = String(d.getHours()).padStart(2, "0");
        const mm = String(d.getMinutes()).padStart(2, "0");
        const ss = String(d.getSeconds()).padStart(2, "0");
        return hh + ":" + mm + ":" + ss;
    }

    function longDate(): string {
        const d = new Date();
        return theme.monthNames[d.getMonth()] + " " + d.getDate() + ", " + d.getFullYear();
    }

    function calTitle(): string {
        const d = new Date();
        return theme.monthNames[d.getMonth()] + " " + d.getFullYear();
    }

    function weekdayModel(): var {
        return theme.weekdayNames;
    }

    function buildCells(_bump): var {
        const now = new Date();
        const year = now.getFullYear();
        const month = now.getMonth();
        const today = now.getDate();

        const cells = [];
        const firstDow = new Date(year, month, 1).getDay();
        for (let i = 0; i < firstDow; i++) cells.push({ label: "", isToday: false });
        const daysInMonth = new Date(year, month + 1, 0).getDate();
        for (let day = 1; day <= daysInMonth; day++) {
            cells.push({ label: String(day), isToday: day === today });
        }
        return cells;
    }

    function refreshDateAndCalendar() {
        root.refreshCount++;
        dateText.text = root.longDate();
        monthHeader.text = root.calTitle();
    }
}