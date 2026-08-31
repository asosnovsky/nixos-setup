import QtQuick

Item {
    id: root

    required property var theme
    required property var workspace
    required property var toplevels
    required property int selectedIndex
    required property bool live

    signal cardClicked(int index)
    signal cardHovered(int index)

    // Slot cards are centered on when nothing in this row is selected (e.g.
    // it's not the active row), so an inactive row still reads as centered.
    readonly property int centerIndex: selectedIndex >= 0 ? selectedIndex : Math.floor((toplevels.length - 1) / 2)

    height: label.implicitHeight + theme.cardSpacing * 0.5 + theme.cardHeight

    Text {
        id: label
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        text: "Workspace " + (root.workspace ? root.workspace.id : "?")
        color: root.theme.textColor
        font.pixelSize: 14
        font.bold: root.workspace && root.workspace.active
    }

    Item {
        id: cardArea
        anchors.top: label.bottom
        anchors.topMargin: root.theme.cardSpacing * 0.5
        anchors.left: parent.left
        anchors.right: parent.right
        height: root.theme.cardHeight

        Repeater {
            model: root.toplevels

            WindowCard {
                required property var modelData
                required property int index

                theme: root.theme
                toplevel: modelData
                selected: index === root.selectedIndex
                live: root.live

                anchors.verticalCenter: parent.verticalCenter
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.horizontalCenterOffset: (index - root.centerIndex) * root.theme.carouselStepX
                opacity: 1 - Math.min(Math.abs(index - root.centerIndex) * root.theme.carouselFadeStep, root.theme.carouselMaxFade)
                scale: 1 - Math.min(Math.abs(index - root.centerIndex) * root.theme.carouselScaleStep, root.theme.carouselMaxScaleReduction)

                Behavior on anchors.horizontalCenterOffset {
                    NumberAnimation { duration: root.theme.carouselDuration; easing.type: Easing.OutCubic }
                }
                Behavior on opacity {
                    NumberAnimation { duration: root.theme.carouselDuration }
                }
                Behavior on scale {
                    NumberAnimation { duration: root.theme.carouselDuration }
                }

                onActivated: root.cardClicked(index)
                onHovered: root.cardHovered(index)
            }
        }

        // Placeholder for an empty workspace so the row stays visible
        // and selectable even with no windows.
        Rectangle {
            visible: root.toplevels.length === 0
            anchors.centerIn: parent
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
