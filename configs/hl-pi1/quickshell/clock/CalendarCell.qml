import QtQuick

// One cell in the clock calendar grid. Empty label = blank spacer (leading
// padding days); today is outlined in the accent color.
Item {
    id: cell

    property string label: ""
    property bool isToday: false
    property real cellSize: 44
    property color accent: "#ffffff"
    property string fontFamily: "DejaVu Sans Mono"
    property real fontSize: 20

    width: cell.cellSize
    height: cell.cellSize

    // Today gets a subtle accent border.
    Rectangle {
        anchors.centerIn: parent
        width: cell.cellSize - 4
        height: cell.cellSize - 4
        radius: 8
        color: cell.isToday ? "#1fffffff" : "transparent"
        border.width: cell.isToday ? 2 : 0
        border.color: cell.accent
        visible: cell.label !== ""
    }

    Text {
        anchors.centerIn: parent
        color: cell.isToday ? cell.accent : "#99ffffff"
        font.family: cell.fontFamily
        font.pixelSize: cell.fontSize
        text: cell.label
    }
}