import Quickshell
import QtQuick
import "../../config" as Config
import "." as Panels
import "../bar" as Bar
import "../bar/PomodoroRing.js" as PomodoroRing
import "../../services/PomodoroPhases.js" as PomodoroPhases

// The pomodoro's popup: the time left, the focus durations and the timer
// controls. Inside a capsule it is the pomodoro's ring view instead: a ring
// of the time left in the phase, in the phase's colour, round large mm:ss
// and the phase's name, with pause/resume, skip and stop.
BarPopup {
    id: root

    required property var pomodoro

    popup: "pomodoro"
    popupWidth: 320

    Config.Theme {
        id: theme
    }

    Column {
        width: parent.width
        spacing: 8

        // Inside a capsule: the ring view.
        Column {
            id: ringView

            readonly property color phaseColor: PomodoroRing.phaseColor(root.pomodoro.phase, theme)

            visible: root.inside
            width: parent.width
            spacing: 10

            Item {
                width: parent.width
                height: ring.height

                Bar.PomodoroRingShape {
                    id: ring

                    anchors.horizontalCenter: parent.horizontalCenter
                    size: 132
                    thickness: 8
                    fraction: PomodoroRing.fraction(root.pomodoro.remainingSeconds, root.pomodoro.phaseSeconds)
                    color: ringView.phaseColor
                    trackColor: theme.surfaceHover
                    opacity: root.pomodoro.running || !root.pomodoro.started ? 1 : 0.6
                }

                Column {
                    anchors.centerIn: ring
                    spacing: 0

                    Panels.ShellText {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: root.pomodoro.remainingLabel
                        color: theme.text
                        font.pixelSize: 34
                        font.bold: true
                    }

                    PopupLabel {
                        anchors.horizontalCenter: parent.horizontalCenter
                        appearance: root.appearance
                        text: PomodoroRing.phaseName(root.pomodoro.phase)
                            + (root.pomodoro.started && !root.pomodoro.running ? " · paused" : "")
                        color: ringView.phaseColor
                    }
                }
            }

            // Before a pomodoro starts, its focus duration.
            Row {
                visible: !root.pomodoro.started
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
                    width: root.pomodoro.started ? (parent.width - parent.spacing * 2) / 3 : parent.width
                    label: root.pomodoro.running ? "Pause" : root.pomodoro.started ? "Resume" : "Start"
                    labelColor: ringView.phaseColor
                    labelSize: root.appearance.textSize
                    onActivated: {
                        if (root.pomodoro.running)
                            root.pomodoro.stop();
                        else
                            root.pomodoro.start();
                    }
                }

                PopupButton {
                    visible: root.pomodoro.started
                    appearance: root.appearance
                    width: (parent.width - parent.spacing * 2) / 3
                    label: root.pomodoro.phase === "break" ? "Skip break" : "Skip"
                    labelColor: theme.textMuted
                    onActivated: root.pomodoro.skip()
                }

                PopupButton {
                    visible: root.pomodoro.started
                    appearance: root.appearance
                    width: (parent.width - parent.spacing * 2) / 3
                    label: "Stop"
                    labelColor: theme.red
                    onActivated: root.pomodoro.cancel()
                }
            }
        }

        // Anywhere else: the durations and controls, as before.
        Column {
            visible: !root.inside
            width: parent.width
            spacing: 8

            PopupHeader {
                appearance: root.appearance
                title: "Pomodoro"
            }

            Panels.ShellText {
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
                text: PomodoroPhases.status(root.pomodoro.phase, root.pomodoro.running,
                    root.pomodoro.started)
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
}
