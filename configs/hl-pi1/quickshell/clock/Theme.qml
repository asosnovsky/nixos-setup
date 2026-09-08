import QtQuick

QtObject {
    // Whole screen is black — the clock panel is the desktop.
    readonly property color background: "#000000"
    readonly property color accent: "#ffffff"

    readonly property string fontFamily: "DejaVu Sans Mono"
    readonly property real clockFontSize: 96
    readonly property real dateFontSize: 28
    readonly property real calendarFontSize: 20
    readonly property real headerFontSize: 24
    readonly property real cellSize: 44
    readonly property real cellSpacing: 6

    // Calendar grid: Sunday-first, common for a simple wall calendar.
    readonly property var weekdayNames: ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    readonly property var monthNames: [
        "January", "February", "March", "April", "May", "June",
        "July", "August", "September", "October", "November", "December",
    ]
}