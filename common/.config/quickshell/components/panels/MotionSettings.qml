import QtQuick
import "." as Panels

// How the shell animates (global, not part of any bar profile).
Column {
    id: root

    required property var appearance

    width: parent ? parent.width : 0
    spacing: 14

    Panels.SettingsHeading {
        appearance: root.appearance
        text: "Animations"
        topPadding: 4
    }

    Column {
        width: parent.width

        Panels.SettingsSwitchRow {
            width: parent.width
            appearance: root.appearance
            label: "Reduce motion"
            checked: root.appearance.reduceMotion
            onToggled: root.appearance.reduceMotion = !root.appearance.reduceMotion
        }

        Panels.SettingsHint {
            x: 12
            width: parent.width - 24
            appearance: root.appearance
            text: "Make animations instant."
        }
    }
}
