import QtQuick
import "../../config" as Config

// An on/off switch. It only asks to be toggled: whoever owns the state flips
// `checked`.
Rectangle {
    id: popupSwitch

    required property var appearance
    property bool checked: false
    signal toggled()

    width: 36
    height: 20
    radius: height / 2
    color: checked ? theme.accent : "transparent"
    border.color: checked ? theme.accent : theme.border
    border.width: 1

    Behavior on color {
        ColorAnimation { duration: 140 }
    }

    Config.Theme {
        id: theme
    }

    Rectangle {
        x: popupSwitch.checked ? parent.width - width - 3 : 3
        anchors.verticalCenter: parent.verticalCenter
        width: 14
        height: 14
        radius: 7
        color: popupSwitch.checked ? theme.background : theme.textMuted

        Behavior on x {
            NumberAnimation {
                duration: 140
                easing.type: Easing.OutCubic
            }
        }
    }

    TapHandler {
        onTapped: popupSwitch.toggled()
    }
}
