import QtQuick
import "../../config" as Config

// An on/off pill: a hairline outline while off, filled with the accent while
// on. It only shows `checked`; whoever owns the setting flips it.
Rectangle {
    id: settingsSwitch

    property bool checked: false

    width: 40
    height: 22
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
        x: settingsSwitch.checked ? parent.width - width - 3 : 3
        anchors.verticalCenter: parent.verticalCenter
        width: 16
        height: 16
        radius: 8
        color: settingsSwitch.checked ? theme.background : theme.textMuted

        Behavior on x {
            NumberAnimation {
                duration: 140
                easing.type: Easing.OutCubic
            }
        }
    }
}
