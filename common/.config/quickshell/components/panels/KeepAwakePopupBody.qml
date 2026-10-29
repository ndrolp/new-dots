import QtQuick
import "../../config" as Config

// What the keep-awake popup shows: keep-awake with its on/off switch. Kept
// apart from the popup window so it is tested without Quickshell.
Column {
    id: root

    required property var appearance
    // The shell's keep-awake (services/KeepAwake.qml).
    required property var keepAwake

    spacing: 4

    Config.Theme {
        id: theme
    }

    PopupHeader {
        appearance: root.appearance
        icon: root.keepAwake.on ? "󰅶" : "󰛊"
        iconColor: root.keepAwake.on ? theme.green : theme.textMuted
        title: "Keep-awake"
        subtitle: root.keepAwake.on ? "The screen stays on and the PC won't suspend"
            : "The screen dims, locks and sleeps as usual"

        PopupSwitch {
            appearance: root.appearance
            checked: root.keepAwake.on
            onToggled: root.keepAwake.toggle()
        }
    }
}
