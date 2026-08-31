import QtQuick

Row {
    id: root

    required property var theme
    required property var monitors
    required property string focusedMonitorName

    signal monitorClicked(int index)

    spacing: theme.cardSpacing * 0.5
    visible: monitors.length > 1

    Repeater {
        model: root.monitors

        Rectangle {
            id: pill
            required property var modelData
            required property int index

            readonly property bool active: modelData.name === root.focusedMonitorName

            width: label.implicitWidth + 24
            height: 32
            radius: height / 2
            color: pill.active ? root.theme.selectedBorder : root.theme.cardBg
            border.width: 1
            border.color: root.theme.cardBorder

            Text {
                id: label
                anchors.centerIn: parent
                text: (pill.index + 1) + ": " + pill.modelData.name
                color: root.theme.textColor
                font.pixelSize: 12
                font.bold: pill.active
            }

            MouseArea {
                anchors.fill: parent
                onClicked: root.monitorClicked(pill.index)
            }
        }
    }
}
