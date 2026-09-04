import QtQuick
import QtQuick.Controls
import "../../config" as Config

TextField {
    id: control

    required property var appearance

    height: 36
    leftPadding: 12
    rightPadding: 12
    color: theme.text
    placeholderTextColor: Qt.rgba(theme.text.r, theme.text.g, theme.text.b, 0.6)
    font.pixelSize: appearance.textSize
    font.bold: true
    selectByMouse: true

    Config.Theme {
        id: theme
    }

    background: Rectangle {
        radius: control.appearance.radius
        color: theme.backgroundSecondary
        border.color: control.activeFocus ? theme.accent : "transparent"
        border.width: 1
    }
}
