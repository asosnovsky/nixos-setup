import QtQuick

// Mini-map of the real monitor layout: each pill is positioned and sized
// proportionally to its monitor's actual x/y/resolution in Hyprland's
// compositor space (see conf/monitors.lua), like a display-arrangement UI.
Item {
    id: root

    required property var theme
    required property var monitors
    required property var monitorStats
    required property string focusedMonitorName

    signal monitorClicked(int index)

    readonly property real mapWidth: 240
    readonly property real minPillWidth: 34
    readonly property real minPillHeight: 26

    // Hyprland reports width/height as raw output resolution but x/y in
    // scaled/logical space, so divide by scale to put everything in the
    // same coordinate system before computing positions/sizes.
    function logicalRect(m) {
        return { x: m.x, y: m.y, w: m.width / m.scale, h: m.height / m.scale };
    }

    readonly property var rects: root.monitors.map(root.logicalRect)
    readonly property var bounds: {
        if (root.rects.length === 0) return { minX: 0, minY: 0, maxX: 1, maxY: 1 };
        return {
            minX: Math.min(...root.rects.map(r => r.x)),
            minY: Math.min(...root.rects.map(r => r.y)),
            maxX: Math.max(...root.rects.map(r => r.x + r.w)),
            maxY: Math.max(...root.rects.map(r => r.y + r.h)),
        };
    }
    readonly property real totalWidth: Math.max(1, root.bounds.maxX - root.bounds.minX)
    readonly property real totalHeight: Math.max(1, root.bounds.maxY - root.bounds.minY)
    readonly property real scaleFactor: root.mapWidth / root.totalWidth

    visible: monitors.length > 1
    width: root.totalWidth * root.scaleFactor
    height: root.totalHeight * root.scaleFactor

    Repeater {
        model: root.monitors

        Rectangle {
            id: pill
            required property var modelData
            required property int index

            readonly property bool active: modelData.name === root.focusedMonitorName
            readonly property var rect: root.logicalRect(modelData)

            x: (rect.x - root.bounds.minX) * root.scaleFactor
            y: (rect.y - root.bounds.minY) * root.scaleFactor
            width: Math.max(rect.w * root.scaleFactor, root.minPillWidth)
            height: Math.max(rect.h * root.scaleFactor, root.minPillHeight)
            radius: 6
            color: pill.active ? root.theme.selectedBorder : root.theme.cardBg
            border.width: 1
            border.color: root.theme.cardBorder
            clip: true

            Text {
                anchors.centerIn: parent
                width: parent.width - 4
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
                text: {
                    const s = root.monitorStats[pill.index];
                    return (pill.index + 1) + ": " + pill.modelData.name
                        + (s ? "  " + s.workspaces + "/" + s.windows : "");
                }
                color: root.theme.textColor
                font.pixelSize: Math.max(9, Math.min(11, pill.height * 0.3))
                font.bold: pill.active
            }

            MouseArea {
                anchors.fill: parent
                onClicked: root.monitorClicked(pill.index)
            }
        }
    }
}
