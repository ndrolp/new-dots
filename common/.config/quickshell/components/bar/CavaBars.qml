import QtQuick
import "../../config" as Config

// What the Cava bar element draws: one vertical bar per height, rising from
// the bottom, 1px apart. Flat heights leave a thin line, so the element never
// looks empty.
Item {
    id: root

    // One height from 0 to 1 per bar.
    property var heights: []
    property int barWidth: 3
    property color color: theme.blue
    readonly property int gap: 1
    readonly property real flatHeight: 2

    implicitWidth: heights.length > 0 ? heights.length * (barWidth + gap) - gap : 0

    Config.Theme {
        id: theme
    }

    Repeater {
        model: root.heights.length

        delegate: Rectangle {
            required property int index

            x: index * (root.barWidth + root.gap)
            width: root.barWidth
            height: Math.max(root.flatHeight, root.height * (root.heights[index] || 0))
            anchors.bottom: parent.bottom
            radius: 1
            color: root.color

            Behavior on height {
                NumberAnimation {
                    duration: 50
                }
            }
        }
    }
}
