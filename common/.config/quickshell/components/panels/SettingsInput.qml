import QtQuick
import QtQuick.Controls
import "../../config" as Config

// A text or number field: transparent, with a hairline border that turns
// accent while focused.
TextField {
    id: control

    required property var appearance

    height: 32
    leftPadding: 10
    rightPadding: 10
    color: theme.text
    placeholderTextColor: theme.textDisabled
    font.family: theme.fontFamily
    font.pixelSize: appearance.textSize
    selectByMouse: true

    TapHandler {
        onTapped: control.forceActiveFocus()
    }

    Config.Theme {
        id: theme
    }

    background: Rectangle {
        radius: control.appearance.radius
        color: "transparent"
        border.color: control.activeFocus ? theme.accent : theme.border
        border.width: 1
    }
}
