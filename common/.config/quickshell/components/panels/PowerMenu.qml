import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import "../../config" as Config

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
        property int selectedIndex: 0
        property int confirmationIndex: -1

        screen: modelData
        visible: root.open && focusedMonitor
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
            color: "#b01e1e2e"

            TapHandler {
                onTapped: menu.close()
            }
        }

        Item {
            anchors.fill: parent
            focus: menu.visible

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

        Rectangle {
            anchors.centerIn: parent
            width: Math.min(parent.width - 64, 680)
            height: 190
            radius: root.appearance.radius
            color: Qt.rgba(theme.surface.r, theme.surface.g, theme.surface.b, 0.9)
            border.color: theme.border
            border.width: 1

            Row {
                anchors.fill: parent
                anchors.margins: 18
                spacing: 12

                Repeater {
                    model: menu.powerActions

                    delegate: Rectangle {
                        required property var modelData
                        required property int index

                        readonly property bool selected: index === menu.selectedIndex
                        readonly property bool confirming: selected && menu.confirmationIndex === index
                        width: (parent.width - parent.spacing * 4) / 5
                        height: parent.height
                        radius: root.appearance.radius
                        color: selected ? theme.surfaceHover : theme.backgroundSecondary
                        border.color: confirming ? theme.red : selected ? modelData.color : "transparent"
                        border.width: selected ? 2 : 1

                        Behavior on color { ColorAnimation { duration: 120 } }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.top: parent.top
                            anchors.topMargin: 36
                            text: modelData.icon
                            color: modelData.color
                            font.pixelSize: 34
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.bottom: parent.bottom
                            anchors.bottomMargin: 34
                            text: confirming ? "Confirm" : modelData.label
                            color: theme.text
                            font.family: theme.fontFamily
                            font.pixelSize: root.appearance.textSize
                            font.bold: true
                        }

                        TapHandler {
                            onTapped: {
                                menu.selectedIndex = index;
                                menu.executeCurrent();
                            }
                        }
                    }
                }
            }
        }
    }
}
