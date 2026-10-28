import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import "../../config" as Config
import "." as Panels

Variants {
    id: root

    required property var appearance
    property bool open: false

    signal closeRequested()

    model: Quickshell.screens

    delegate: PanelWindow {
        id: menu

        required property var modelData
        readonly property var monitor: Hyprland.monitorFor(modelData)
        readonly property bool focusedMonitor: Hyprland.focusedWorkspace
            && Hyprland.focusedWorkspace.monitor && monitor
            && Hyprland.focusedWorkspace.monitor.name === monitor.name
        // Open on the focused monitor; the window stays up while it fades out.
        readonly property bool shown: root.open && focusedMonitor
        property int selectedIndex: 0
        property int confirmationIndex: -1

        screen: modelData
        visible: surface.reveal > 0
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        focusable: true
        WlrLayershell.namespace: "ndro-shell-power-menu"
        WlrLayershell.layer: WlrLayer.Overlay

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

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

        readonly property var powerActions: [
            { label: "Lock", icon: "󰌾", color: theme.accent, command: "loginctl lock-session" },
            { label: "Suspend", icon: "󰤄", color: theme.blue, command: "systemctl suspend" },
            { label: "Logout", icon: "󰍃", color: theme.yellow, command: "hyprctl dispatch 'hl.dsp.exit()'" },
            { label: "Reboot", icon: "󰜉", color: theme.orange, command: "systemctl reboot", confirm: true },
            { label: "Shutdown", icon: "󰐥", color: theme.red, command: "systemctl poweroff", confirm: true }
        ]

        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(theme.background.r, theme.background.g, theme.background.b, 0.7)
            opacity: surface.reveal

            TapHandler {
                onTapped: menu.close()
            }
        }

        Item {
            anchors.fill: parent
            focus: menu.shown

            Keys.onEscapePressed: menu.close()
            Keys.onLeftPressed: menu.selectRelative(-1)
            Keys.onRightPressed: menu.selectRelative(1)
            Keys.onPressed: event => {
                if (event.key === Qt.Key_H) {
                    menu.selectRelative(-1);
                    event.accepted = true;
                } else if (event.key === Qt.Key_L) {
                    menu.selectRelative(1);
                    event.accepted = true;
                }
            }
            Keys.onReturnPressed: menu.executeCurrent()
            Keys.onEnterPressed: menu.executeCurrent()
        }

        PopupSurface {
            id: surface

            anchors.centerIn: parent
            width: Math.min(parent.width - 64, 520)
            height: implicitHeight
            open: menu.shown
            enabled: menu.shown
            radius: root.appearance.radius
            motion: root.appearance.motion
            motionEasing: root.appearance.motionEasing

            Column {
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
                        model: menu.powerActions

                        delegate: PopupRow {
                            id: actionTile

                            required property var modelData
                            required property int index

                            readonly property bool selected: index === menu.selectedIndex
                            readonly property bool confirming: selected && menu.confirmationIndex === index

                            appearance: root.appearance
                            width: (actionRow.width - actionRow.spacing * 4) / 5
                            height: 84
                            color: selected || hovered ? theme.surfaceHover : "transparent"

                            Column {
                                anchors.centerIn: parent
                                spacing: 8

                                Panels.Text {
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
                                    menu.selectedIndex = actionTile.index;
                                    menu.executeCurrent();
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
