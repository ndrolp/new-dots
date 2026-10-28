import Quickshell
import QtQuick
import "../../config" as Config
import "." as Panels

// The pomodoro's popup: the time left, the focus durations and the timer controls.
BarPopup {
    id: root

    required property var pomodoro

    popup: "pomodoro"
    implicitWidth: 320

    Config.Theme {
        id: theme
    }

    Column {
        width: parent.width
        spacing: 8

        PopupHeader {
            appearance: root.appearance
            title: "Pomodoro"
        }

        Panels.Text {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            text: root.pomodoro.remainingLabel
            color: root.pomodoro.running ? theme.accent : theme.text
            font.pixelSize: 34
        }

        PopupLabel {
            appearance: root.appearance
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            text: root.pomodoro.running ? "Focus session in progress"
                : root.pomodoro.started ? "Timer paused" : "Choose a focus duration"
        }

        Row {
            width: parent.width
            spacing: 4

            Repeater {
                model: [25, 30, 45, 60]

                delegate: PopupButton {
                    required property int modelData

                    appearance: root.appearance
                    width: (parent.width - parent.spacing * 3) / 4
                    label: modelData === 60 ? "1h" : modelData + "m"
                    labelColor: root.pomodoro.durationSeconds === modelData * 60
                        ? theme.accent : theme.textMuted
                    onActivated: root.pomodoro.selectMinutes(modelData)
                }
            }
        }

        Row {
            width: parent.width
            spacing: 4

            PopupButton {
                appearance: root.appearance
                width: 48
                label: "−10m"
                onActivated: root.pomodoro.adjustMinutes(-10)
            }

            PopupButton {
                appearance: root.appearance
                width: 36
                label: "−1"
                onActivated: root.pomodoro.adjustMinutes(-1)
            }

            PopupButton {
                appearance: root.appearance
                width: parent.width - 168 - parent.spacing * 4
                label: root.pomodoro.running ? "Stop" : root.pomodoro.started ? "Resume" : "Start"
                labelColor: theme.accent
                labelSize: root.appearance.textSize
                onActivated: {
                    if (root.pomodoro.running)
                        root.pomodoro.stop();
                    else
                        root.pomodoro.start();
                }
            }

            PopupButton {
                appearance: root.appearance
                width: 36
                label: "+1"
                onActivated: root.pomodoro.adjustMinutes(1)
            }

            PopupButton {
                appearance: root.appearance
                width: 48
                label: "+10m"
                onActivated: root.pomodoro.adjustMinutes(10)
            }
        }

        PopupButton {
            appearance: root.appearance
            visible: root.pomodoro.started
            width: parent.width
            label: "Cancel timer"
            labelColor: theme.red
            onActivated: root.pomodoro.cancel()
        }
    }
}
