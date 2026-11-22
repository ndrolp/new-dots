import QtQuick
import "../../config" as Config

// An on/off pill: a hairline outline while off, filled with the accent while
// on, brighter while hovered (or while its row is). It only shows `checked`;
// whoever owns the setting flips it.
Rectangle {
    id: settingsSwitch

    required property var appearance
    property bool checked: false
    // Follows the pointer; settable so its look can be checked without one.
    property bool hovered: switchHover.hovered

    width: 40
    height: 22
    radius: height / 2
    color: checked ? (hovered ? Qt.lighter(theme.accent, 1.15) : theme.accent) : "transparent"
    border.color: checked ? color : hovered ? theme.textMuted : theme.border
    border.width: 1

    Behavior on color {
        ColorAnimation { duration: settingsSwitch.appearance.motion.short }
    }

    Behavior on border.color {
        ColorAnimation { duration: settingsSwitch.appearance.motion.short }
    }

    HoverHandler {
        id: switchHover

        cursorShape: Qt.PointingHandCursor
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
        color: settingsSwitch.checked ? theme.background : settingsSwitch.hovered ? theme.text : theme.textMuted

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
