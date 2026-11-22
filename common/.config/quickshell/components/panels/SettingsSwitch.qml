import QtQuick
import "../../config" as Config
import "." as Panels

// An on/off pill: a hairline outline while off, filled with the accent while
// on, the accent's hover colour while hovered (or while its row is). It only
// shows `checked`; whoever owns the setting flips it.
Panels.SettingsHoverFill {
    id: settingsSwitch

    property bool checked: false

    width: 40
    height: 22
    radius: height / 2
    color: checked ? (hovering ? theme.accentHover : theme.accent) : "transparent"
    border.color: checked ? color : hovering ? theme.textMuted : theme.border
    border.width: 1

    Behavior on border.color {
        ColorAnimation { duration: settingsSwitch.appearance.motion.short }
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
        color: settingsSwitch.checked ? theme.background : settingsSwitch.hovering ? theme.text : theme.textMuted

        Behavior on color {
            ColorAnimation { duration: settingsSwitch.appearance.motion.short }
        }

        Behavior on x {
            NumberAnimation {
                duration: settingsSwitch.appearance.motion.short
                easing.type: settingsSwitch.appearance.motion.easing
            }
        }
    }
}
