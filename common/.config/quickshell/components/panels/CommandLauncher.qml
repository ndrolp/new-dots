import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Controls
import "../../config" as Config

Variants {
    id: root

    required property var appearance
    property bool open: false

    signal closeRequested()

    model: Quickshell.screens

    delegate: PanelWindow {
        id: launcher

        required property var modelData
        readonly property var monitor: Hyprland.monitorFor(modelData)
        readonly property bool focusedMonitor: Hyprland.focusedWorkspace
            && Hyprland.focusedWorkspace.monitor && monitor
            && Hyprland.focusedWorkspace.monitor.name === monitor.name
        property string commandText: ""

        screen: modelData
        visible: root.open && focusedMonitor
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        focusable: true
        WlrLayershell.namespace: "ndro-shell-command-launcher"
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
            id: commandRunner
        }

        function close() {
            root.closeRequested();
        }

        function runCommand() {
            const command = commandText.trim();

            if (command === "")
                return;

            commandRunner.command = ["kitty", "-e", "sh", "-lc", command];
            commandRunner.running = true;
            close();
        }

        onVisibleChanged: {
            if (!visible)
                return;

            commandText = "";
            inputFocusTimer.restart();
        }

        Timer {
            id: inputFocusTimer

            interval: 1
            onTriggered: commandInput.forceActiveFocus()
        }

        Rectangle {
            anchors.fill: parent
            color: "transparent"

            MouseArea {
                onClicked: launcher.close()
            }
        }

        Item {
            anchors.fill: parent
            focus: launcher.visible

            Keys.onEscapePressed: launcher.close()
        }

        Rectangle {
            anchors.centerIn: parent
            width: Math.min(parent.width - 64, 640)
            height: 82
            radius: root.appearance.radius
            color: Qt.rgba(theme.surface.r, theme.surface.g, theme.surface.b, 0.84)
            border.color: theme.border
            border.width: 1

            TextField {
                id: commandInput

                anchors.fill: parent
                anchors.margins: 12
                leftPadding: 40
                rightPadding: 12
                placeholderText: "Run command in Kitty"
                placeholderTextColor: Qt.rgba(theme.text.r, theme.text.g, theme.text.b, 0.6)
                color: theme.text
                font.family: theme.fontFamily
                font.pixelSize: root.appearance.textSize + 1
                font.bold: true
                selectByMouse: true
                text: launcher.commandText
                focus: launcher.visible

                background: Rectangle {
                    radius: root.appearance.radius
                    color: Qt.rgba(theme.backgroundSecondary.r, theme.backgroundSecondary.g,
                        theme.backgroundSecondary.b, 0.7)
                    border.color: commandInput.activeFocus ? theme.accent : "transparent"
                    border.width: 1
                }

                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    text: ""
                    color: theme.accent
                    font.family: theme.fontFamily
                    font.pixelSize: 18
                }

                onTextEdited: launcher.commandText = text
                onAccepted: launcher.runCommand()
                Keys.onEscapePressed: launcher.close()
            }
        }
    }
}
