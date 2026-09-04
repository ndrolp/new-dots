import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import QtQuick
import "../../config" as Config

Variants {
    id: root

    required property var appearance
    required property var screenCapture
    property bool open: false

    signal closeRequested()

    model: Quickshell.screens

    delegate: PanelWindow {
        id: chooser

        required property var modelData
        readonly property var monitor: Hyprland.monitorFor(modelData)
        readonly property bool focusedMonitor: Hyprland.focusedWorkspace
            && Hyprland.focusedWorkspace.monitor && monitor
            && Hyprland.focusedWorkspace.monitor.name === monitor.name
        readonly property string monitorName: monitor ? monitor.name : ""

        screen: modelData
        visible: root.open && focusedMonitor
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        focusable: true
        WlrLayershell.namespace: "ndro-shell-screen-capture"
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

        function close() {
            root.closeRequested();
        }

        function runAction(action) {
            if (action === "screenshot-region")
                root.screenCapture.screenshotRegion();
            else if (action === "screenshot-output")
                root.screenCapture.screenshotOutput(monitorName);
            else if (action === "record-region")
                root.screenCapture.recordRegion();
            else if (action === "record-output")
                root.screenCapture.recordOutput(monitorName);
            else if (action === "stop-recording")
                root.screenCapture.stopRecording();

            if (action !== "stop-recording")
                close();
        }

        Rectangle {
            anchors.fill: parent
            color: "transparent"

            TapHandler {
                onTapped: chooser.close()
            }
        }

        Item {
            anchors.fill: parent
            focus: chooser.visible

            Keys.onEscapePressed: {
                if (root.screenCapture.recording)
                    root.screenCapture.stopRecording();
                chooser.close();
            }
            Keys.onReturnPressed: chooser.runAction("screenshot-region")
            Keys.onEnterPressed: chooser.runAction("screenshot-region")
            Keys.onPressed: event => {
                if (event.key === Qt.Key_1)
                    chooser.runAction("screenshot-region");
                else if (event.key === Qt.Key_2)
                    chooser.runAction("screenshot-output");
                else if (event.key === Qt.Key_3)
                    chooser.runAction("record-region");
                else if (event.key === Qt.Key_4)
                    chooser.runAction("record-output");
                else if (event.key === Qt.Key_R && root.screenCapture.recording) {
                    root.screenCapture.stopRecording();
                    chooser.close();
                } else {
                    return;
                }

                event.accepted = true;
            }
        }

        Rectangle {
            anchors.centerIn: parent
            width: Math.min(parent.width - 48, 500)
            height: content.implicitHeight + 40
            radius: root.appearance.radius
            color: theme.surface
            border.color: theme.border
            border.width: 1

            Column {
                id: content

                anchors.fill: parent
                anchors.margins: 20
                spacing: 12

                Text {
                    width: parent.width
                    text: root.screenCapture.recording ? "SCREEN RECORDING" : "SCREEN CAPTURE"
                    color: theme.text
                    font.family: theme.fontFamily
                    font.pixelSize: root.appearance.textSize + 5
                    font.bold: true
                }

                Text {
                    width: parent.width
                    text: root.screenCapture.recording
                        ? "Recording this output. Press R or Escape to stop and save."
                        : "Save to " + (root.screenCapture.outputDirectory === ""
                            ? "your Pictures directory" : root.screenCapture.outputDirectory)
                    color: theme.textMuted
                    font.family: theme.fontFamily
                    font.pixelSize: root.appearance.textSize - 1
                    wrapMode: Text.Wrap
                }

                Repeater {
                    model: root.screenCapture.recording ? [{
                        label: "Stop recording",
                        detail: "R · Escape",
                        action: "stop-recording",
                        enabled: true
                    }] : [{
                        label: "Capture region",
                        detail: "1 · Enter · grim + slurp",
                        action: "screenshot-region",
                        enabled: root.screenCapture.grimAvailable && root.screenCapture.slurpAvailable
                    }, {
                        label: "Capture focused display",
                        detail: "2 · " + (root.screenCapture.grimAvailable ? "grim" : "wayshot"),
                        action: "screenshot-output",
                        enabled: root.screenCapture.grimAvailable || root.screenCapture.wayshotAvailable
                    }, {
                        label: "Record region",
                        detail: "3 · wf-recorder + slurp",
                        action: "record-region",
                        enabled: root.screenCapture.wfRecorderAvailable
                            && root.screenCapture.slurpAvailable
                    }, {
                        label: "Record focused display",
                        detail: "4 · wf-recorder",
                        action: "record-output",
                        enabled: root.screenCapture.wfRecorderAvailable
                    }]

                    delegate: Rectangle {
                        required property var modelData

                        width: content.width
                        height: 52
                        radius: root.appearance.radius
                        color: !modelData.enabled ? theme.backgroundSecondary
                            : actionHover.hovered ? theme.surfaceHover : theme.backgroundSecondary
                        opacity: modelData.enabled ? 1 : 0.5

                        HoverHandler {
                            id: actionHover
                            enabled: modelData.enabled
                        }

                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.margins: 12
                            spacing: 2

                            Text {
                                text: modelData.label
                                color: theme.text
                                font.family: theme.fontFamily
                                font.pixelSize: root.appearance.textSize
                                font.bold: true
                            }

                            Text {
                                text: modelData.detail
                                color: theme.textMuted
                                font.family: theme.fontFamily
                                font.pixelSize: root.appearance.textSize - 3
                            }
                        }

                        TapHandler {
                            enabled: modelData.enabled
                            onTapped: chooser.runAction(modelData.action)
                        }
                    }
                }

                Text {
                    width: parent.width
                    text: root.screenCapture.status
                    visible: text !== ""
                    color: theme.textMuted
                    font.family: theme.fontFamily
                    font.pixelSize: root.appearance.textSize - 2
                    wrapMode: Text.Wrap
                }
            }
        }
    }
}
