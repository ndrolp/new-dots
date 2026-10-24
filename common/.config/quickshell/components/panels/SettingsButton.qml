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
    signal activated()

    width: buttonLabel.implicitWidth + 28
    height: 32
    radius: appearance.radius
    color: buttonHover.hovered && enabled ? theme.surfaceHover : "transparent"
    opacity: enabled ? 1 : 0.4

    Behavior on color {
        ColorAnimation { duration: 140 }
    }

    Config.Theme {
        id: theme
    }

    HoverHandler {
        id: buttonHover
    }

    Panels.Text {
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
