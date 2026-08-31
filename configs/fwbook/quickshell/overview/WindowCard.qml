import QtQuick
import Quickshell
import Quickshell.Wayland

Rectangle {
    id: root

    required property var theme
    required property var toplevel
    required property bool selected
    required property bool live

    signal activated()
    signal hovered()

    readonly property var ipc: root.toplevel ? root.toplevel.lastIpcObject : null
    readonly property real aspect: (ipc && ipc.size && ipc.size[0] > 0 && ipc.size[1] > 0) ? ipc.size[0] / ipc.size[1] : (16 / 9)

    width: Math.min(height * aspect, theme.cardHeight * 2.2)
    height: theme.cardHeight
    radius: theme.cornerRadius
    color: theme.cardBg
    border.width: selected ? 3 : 1
    border.color: selected ? theme.selectedBorder : theme.cardBorder
    clip: true

    ScreencopyView {
        anchors.fill: parent
        anchors.margins: 3
        captureSource: root.live && root.toplevel ? root.toplevel.wayland : null
        live: root.live
        paintCursor: false
    }

    Image {
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.margins: 6
        width: 20
        height: 20
        source: Quickshell.iconPath(ipc ? ipc.class : "", "application-x-executable")
        sourceSize: Qt.size(20, 20)
    }

    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: title.implicitHeight + 8
        color: "#99000000"

        Text {
            id: title
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: 30
            anchors.rightMargin: 6
            anchors.verticalCenter: parent.verticalCenter
            elide: Text.ElideRight
            color: theme.textColor
            text: root.toplevel ? root.toplevel.title : ""
            font.pixelSize: 12
        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onClicked: root.activated()
        onEntered: root.hovered()
    }
}
