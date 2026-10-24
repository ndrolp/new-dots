import QtQuick
import "../../config" as Config
import "." as Panels

// A quiet text button: its label alone, with a faint fill only while hovered.
Rectangle {
    id: button

    required property var appearance
    property string label: ""
    property color labelColor: theme.text
    signal activated()

    width: buttonLabel.implicitWidth + 28
    height: 32
    radius: appearance.radius
    color: buttonHover.hovered ? theme.surfaceHover : "transparent"

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
        onTapped: button.activated()
    }
}
