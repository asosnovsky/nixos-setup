import QtQuick

Item {
    id: root

    required property var theme
    required property var workspace
    required property var toplevels
    required property int selectedIndex
    required property bool live

    signal cardClicked(int index)

    implicitWidth: content.implicitWidth
    implicitHeight: content.implicitHeight

    Column {
        id: content
        spacing: root.theme.cardSpacing * 0.5

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "Workspace " + (root.workspace ? root.workspace.id : "?")
            color: root.theme.textColor
            font.pixelSize: 14
            font.bold: root.workspace && root.workspace.active
        }

        Row {
            spacing: root.theme.cardSpacing

            Repeater {
                model: root.toplevels

                WindowCard {
                    required property var modelData
                    required property int index

                    theme: root.theme
                    toplevel: modelData
                    selected: index === root.selectedIndex
                    live: root.live

                    onActivated: root.cardClicked(index)
                }
            }

            // Placeholder for an empty workspace so the row stays visible
            // and selectable even with no windows.
            Rectangle {
                visible: root.toplevels.length === 0
                width: root.theme.cardHeight * 1.6
                height: root.theme.cardHeight
                radius: root.theme.cornerRadius
                color: "transparent"
                border.width: root.selectedIndex === 0 ? 3 : 1
                border.color: root.selectedIndex === 0 ? root.theme.selectedBorder : root.theme.cardBorder

                Text {
                    anchors.centerIn: parent
                    text: "Empty"
                    color: root.theme.emptyTextColor
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: root.cardClicked(0)
                }
            }
        }
    }
}
