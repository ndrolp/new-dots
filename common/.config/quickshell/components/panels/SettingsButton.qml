import QtQuick
import "../../config" as Config
import "." as Panels

// A quiet text button: its label alone, with a faint fill only while hovered.
// A disabled button is dimmed and can't be pressed.
Panels.SettingsHoverFill {
    id: button

    property string label: ""
    property color labelColor: theme.text
    signal activated()

    implicitWidth: buttonLabel.implicitWidth + 28
    implicitHeight: 32
    radius: appearance.radius
    color: hovering && enabled ? theme.cardHover : "transparent"
    opacity: enabled ? 1 : 0.4
    cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor

    Config.Theme {
        id: theme
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
