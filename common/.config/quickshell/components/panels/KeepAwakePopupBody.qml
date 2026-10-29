import QtQuick
import "../../config" as Config
import "../../services/KeepAwakeState.js" as KeepAwakeState

// What the keep-awake popup shows: keep-awake with its on/off switch, the
// time left while a timed keep-awake runs and the duration choice, which
// turning it on from anywhere uses. Kept apart from the popup window so it is
// tested without Quickshell.
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

    PopupLabel {
        appearance: root.appearance
        visible: root.keepAwake.timed
        width: parent.width
        horizontalAlignment: Text.AlignHCenter
        text: KeepAwakeState.timeLeftLabel(root.keepAwake.secondsLeft) + " left"
    }

    Row {
        id: durations

        width: parent.width
        spacing: 4

        Repeater {
            model: KeepAwakeState.durations

            delegate: PopupButton {
                required property var modelData

                appearance: root.appearance
                // "Until turned off" takes the room its longer label needs.
                width: modelData.minutes === 0 ? durations.width * 0.4
                    : (durations.width * 0.6 - durations.spacing * 3) / 3
                label: modelData.label
                labelColor: root.keepAwake.duration === modelData.minutes ? theme.accent : theme.textMuted
                onActivated: root.keepAwake.chooseDuration(modelData.minutes)
            }
        }
    }
}
