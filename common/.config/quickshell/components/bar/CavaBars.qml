import QtQuick
import "../BarPosition.js" as BarPosition
import "../../config" as Config
import "../../services/CavaOutput.js" as CavaOutput

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
    property real barWidth: 3
    // The Bar position.
    property string barPosition: "top"
    // One of the theme's named colors, so it follows the theme, or "white".
    property string colorName: "blue"
    // How long a bar takes to reach its next height (appearance.motion.frame).
    property int smoothing: 0
    // The played fraction of the track, from 0 to 1: on a top or bottom bar,
    // the bars are painted in `progressColorName` from the left up to that
    // point, splitting the bar it falls in. Below 0, nothing is painted.
    property real progress: -1
    property string progressColorName: "accent"
    readonly property color progressColor: progressColorName === "white" ? "#ffffff"
        : theme[progressColorName] || theme.accent
    readonly property real progressX: progress < 0 || sideBar ? -1 : width * Math.min(1, progress)
    readonly property var heights: CavaOutput.resample(frame, barCount)
    readonly property color color: colorName === "white" ? "#ffffff" : theme[colorName] || theme.blue
    property real gap: 1
    readonly property real flatHeight: 2

    readonly property bool sideBar: BarPosition.sideBar(barPosition)
    readonly property int length: barCount > 0 ? barCount * (barWidth + gap) - gap : 0

    implicitWidth: sideBar ? 0 : length
    implicitHeight: sideBar ? length : 0

    Config.Theme {
        id: theme
    }

    Repeater {
        model: root.barCount

        delegate: Rectangle {
            required property int index

            readonly property real start: index * (root.barWidth + root.gap)
            readonly property real level: root.heights[index] || 0

            x: !root.sideBar ? start : root.barPosition === "right" ? root.width - width : 0
            y: root.sideBar ? start : root.height - height
            width: root.sideBar ? Math.max(root.flatHeight, root.width * level) : root.barWidth
            height: root.sideBar ? root.barWidth : Math.max(root.flatHeight, root.height * level)
            radius: 1
            color: root.color

            // The played part of this bar, in the progress color.
            Rectangle {
                objectName: "barProgress"
                width: Math.max(0, Math.min(parent.width, root.progressX - parent.x))
                height: parent.height
                visible: width > 0
                radius: parent.radius
                color: root.progressColor
            }

            Behavior on width {
                enabled: root.sideBar

                NumberAnimation {
                    duration: root.smoothing
                }
            }

            Behavior on height {
                enabled: !root.sideBar

                NumberAnimation {
                    duration: root.smoothing
                }
            }
        }
    }
}
