import QtQuick
import "../../config" as Config
import "." as Panels

// A quiet text button: its label alone, with a faint fill only while hovered.
// A disabled button is dimmed and can't be pressed.
Rectangle {
    id: button

    required property var appearance
    property string label: ""
    property color labelColor: theme.text
    // Follows the pointer; settable so its look can be checked without one.
    property bool hovered: buttonHover.hovered
    signal activated()

    implicitWidth: buttonLabel.implicitWidth + 28
    implicitHeight: 32
    radius: appearance.radius
    color: hovered && enabled ? theme.surfaceHover : "transparent"
    opacity: enabled ? 1 : 0.4

    Behavior on color {
        ColorAnimation { duration: button.appearance.motion.short }
    }

    Config.Theme {
        id: theme
    }

    HoverHandler {
        id: buttonHover

        cursorShape: button.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
    }

    Panels.ShellText {
        id: buttonLabel

        anchors.centerIn: parent
        text: button.label
        color: button.labelColor
        font.pixelSize: button.appearance.textSize
    }

    TapHandler {
        enabled: button.enabled
        onTapped: button.activated()
    }
}
