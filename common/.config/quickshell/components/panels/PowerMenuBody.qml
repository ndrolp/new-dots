import Quickshell.Io
import QtQuick
import "../../config" as Config
import "." as Panels

// The power menu: one row of its five actions (lock, suspend, log out,
// reboot, shut down). H/L or the arrows move, Enter runs the selected one;
// reboot and shut down ask to be pressed again. Shown full-screen
// (PowerMenu.qml) or inside a capsule (PowerMenuPopup.qml); `active` is true
// while it is shown.
Item {
    id: root

    required property var appearance
    // Shown: becoming true selects the first action, with the keys focused.
    property bool active: false
    property int selectedIndex: 0
    property int confirmationIndex: -1

    signal closeRequested()

    readonly property var powerActions: [
        { label: "Lock", icon: "󰌾", color: theme.accent, command: "loginctl lock-session" },
        { label: "Suspend", icon: "󰤄", color: theme.blue, command: "systemctl suspend" },
        { label: "Logout", icon: "󰍃", color: theme.yellow, command: "hyprctl dispatch 'hl.dsp.exit()'" },
        { label: "Reboot", icon: "󰜉", color: theme.orange, command: "systemctl reboot", confirm: true },
        { label: "Shutdown", icon: "󰐥", color: theme.red, command: "systemctl poweroff", confirm: true }
    ]

    implicitHeight: content.implicitHeight

    Config.Theme {
        id: theme
    }

    Process {
        id: actionProcess
    }

    function close() {
        root.closeRequested();
    }

    function selectRelative(offset) {
        selectedIndex = (selectedIndex + offset + powerActions.length) % powerActions.length;
        confirmationIndex = -1;
    }

    function executeCurrent() {
        const action = powerActions[selectedIndex];

        if (action.confirm && confirmationIndex !== selectedIndex) {
            confirmationIndex = selectedIndex;
            return;
        }

        actionProcess.command = ["sh", "-c", action.command];
        actionProcess.running = true;
        close();
    }

    onActiveChanged: {
        if (active) {
            selectedIndex = 0;
            confirmationIndex = -1;
            keys.forceActiveFocus();
        }
    }

    Item {
        id: keys

        anchors.fill: parent
        focus: root.active

        Keys.onEscapePressed: root.close()
        Keys.onLeftPressed: root.selectRelative(-1)
        Keys.onRightPressed: root.selectRelative(1)
        Keys.onPressed: event => {
            if (event.key === Qt.Key_H) {
                root.selectRelative(-1);
                event.accepted = true;
            } else if (event.key === Qt.Key_L) {
                root.selectRelative(1);
                event.accepted = true;
            }
        }
        Keys.onReturnPressed: root.executeCurrent()
        Keys.onEnterPressed: root.executeCurrent()
    }

    Column {
        id: content

        width: parent.width
        spacing: 10

        PopupHeader {
            appearance: root.appearance
            icon: "󰐥"
            title: "Power"
            subtitle: "H / L or arrows · Enter to choose"
        }

        Row {
            id: actionRow

            width: parent.width
            spacing: 4

            Repeater {
                model: root.powerActions

                delegate: PopupRow {
                    id: actionTile

                    required property var modelData
                    required property int index

                    readonly property bool selected: index === root.selectedIndex
                    readonly property bool confirming: selected && root.confirmationIndex === index

                    appearance: root.appearance
                    width: (actionRow.width - actionRow.spacing * 4) / 5
                    height: 84
                    color: selected || hovered ? theme.surfaceHover : "transparent"

                    Column {
                        anchors.centerIn: parent
                        spacing: 8

                        Panels.ShellText {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: actionTile.modelData.icon
                            color: actionTile.confirming ? theme.red
                                : actionTile.selected || actionTile.hovered ? actionTile.modelData.color
                                : theme.textMuted
                            font.pixelSize: root.appearance.textSize + 13

                            Behavior on color {
                                ColorAnimation { duration: root.appearance.motion.short }
                            }
                        }

                        PopupLabel {
                            anchors.horizontalCenter: parent.horizontalCenter
                            appearance: root.appearance
                            text: actionTile.confirming ? "Confirm" : actionTile.modelData.label
                            color: actionTile.confirming ? theme.red
                                : actionTile.selected ? theme.text
                                : theme.textMuted
                            font.pixelSize: root.appearance.textSize - 1
                        }
                    }

                    TapHandler {
                        onTapped: {
                            root.selectedIndex = actionTile.index;
                            root.executeCurrent();
                        }
                    }
                }
            }
        }
    }
}
