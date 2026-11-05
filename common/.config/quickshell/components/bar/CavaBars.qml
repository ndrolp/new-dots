import QtQuick
import "../../config" as Config
import "../../services/CavaOutput.js" as CavaOutput
import "BarLayout.js" as BarLayout

// What the Cava bar element draws: `barCount` bars 1px apart, resampled from
// the frame the shared cava prints. On a top or bottom bar they rise from the
// bottom; on a side bar they run down it and grow from the screen's edge. Flat
// heights leave a thin line, so the element never looks empty.
Item {
    id: root

    // The latest frame of the shared cava, one height from 0 to 1 per bar;
    // it may hold more bars than this draws.
    property var frame: []
    property int barCount: 12
    property int barWidth: 3
    // The Bar position.
    property string barPosition: "top"
    // One of the theme's named colors, so it follows the theme.
    property string colorName: "blue"
    // How long a bar takes to reach its next height (appearance.motion.frame).
    property int smoothing: 0
    readonly property var heights: CavaOutput.resample(frame, barCount)
    readonly property color color: theme[colorName] || theme.blue
    readonly property int gap: 1
    readonly property real flatHeight: 2

    readonly property bool vertical: BarLayout.vertical({ barPosition: barPosition })
    readonly property int length: barCount > 0 ? barCount * (barWidth + gap) - gap : 0

    implicitWidth: vertical ? 0 : length
    implicitHeight: vertical ? length : 0

    Config.Theme {
        id: theme
    }

    Repeater {
        model: root.barCount

        delegate: Rectangle {
            required property int index

            readonly property real start: index * (root.barWidth + root.gap)
            readonly property real level: root.heights[index] || 0

            x: !root.vertical ? start : root.barPosition === "right" ? root.width - width : 0
            y: root.vertical ? start : root.height - height
            width: root.vertical ? Math.max(root.flatHeight, root.width * level) : root.barWidth
            height: root.vertical ? root.barWidth : Math.max(root.flatHeight, root.height * level)
            radius: 1
            color: root.color

            Behavior on width {
                enabled: root.vertical

                NumberAnimation {
                    duration: root.smoothing
                }
            }

            Behavior on height {
                enabled: !root.vertical

                NumberAnimation {
                    duration: root.smoothing
                }
            }
        }
    }
}
