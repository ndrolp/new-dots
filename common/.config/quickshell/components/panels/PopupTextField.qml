import QtQuick
import QtQuick.Controls
import "../../config" as Config

// A text input with a hairline border that turns accent while focused.
TextField {
    id: field

    required property var appearance

    color: theme.text
    placeholderTextColor: theme.textDisabled
    font.family: theme.fontFamily
    font.pixelSize: appearance.textSize - 1
    selectByMouse: true

    background: Rectangle {
        radius: field.appearance.radius
        color: "transparent"
        border.color: field.activeFocus ? theme.accent : theme.border
        border.width: 1
    }

    Config.Theme {
        id: theme
    }
}
