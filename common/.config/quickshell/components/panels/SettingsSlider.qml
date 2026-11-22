import QtQuick
import QtQuick.Controls
import "../../config" as Config

// A slider: a thin track, like a popup's progress bar, filled with the accent
// up to a round accent handle, which grows under the pointer.
Slider {
    id: control

    required property var appearance
    // Follows the pointer; settable so its look can be checked without one
    // (a control's own `hovered` is read-only).
    property bool hovering: sliderHover.hovered

    HoverHandler {
        id: sliderHover

        cursorShape: Qt.PointingHandCursor
    }

    background: Rectangle {
        x: control.leftPadding
        y: control.topPadding + (control.availableHeight - height) / 2
        width: control.availableWidth
        height: 4
        radius: 2
        color: theme.backgroundSecondary

        Rectangle {
            width: parent.width * control.visualPosition
            height: parent.height
            radius: parent.radius
            color: theme.accent
        }
    }

    Config.Theme {
        id: theme
    }

    handle: Rectangle {
        x: control.leftPadding + control.visualPosition * (control.availableWidth - width)
        y: control.topPadding + (control.availableHeight - height) / 2
        width: control.hovering || control.pressed ? 18 : 14
        height: width
        radius: width / 2
        color: theme.accent

        Behavior on width {
            NumberAnimation {
                duration: control.appearance.motion.short
                easing.type: control.appearance.motion.easing
            }
        }
    }
}
