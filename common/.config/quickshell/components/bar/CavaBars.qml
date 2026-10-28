import QtQuick
import "../../config" as Config
import "../../services/CavaOutput.js" as CavaOutput

// What the Cava bar element draws: `barCount` vertical bars rising from the
// bottom, 1px apart, resampled from the frame the shared cava prints. Flat
// heights leave a thin line, so the element never looks empty.
Item {
    id: root

    // The latest frame of the shared cava, one height from 0 to 1 per bar;
    // it may hold more bars than this draws.
    property var frame: []
    property int barCount: 12
    property int barWidth: 3
    // One of the theme's named colors, so it follows the theme.
    property string colorName: "blue"
    // How long a bar takes to reach its next height (appearance.motion.frame).
    property int smoothing: 0
    readonly property var heights: CavaOutput.resample(frame, barCount)
    readonly property color color: theme[colorName] || theme.blue
    readonly property int gap: 1
    readonly property real flatHeight: 2

    implicitWidth: barCount > 0 ? barCount * (barWidth + gap) - gap : 0

    Config.Theme {
        id: theme
    }

    Repeater {
        model: root.barCount

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
                    duration: root.smoothing
                }
            }
        }
    }
}
