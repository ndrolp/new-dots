import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Widgets
import QtQuick
import QtQuick.Controls
import "../../config" as Config
import "../IconSource.js" as IconSource

Variants {
    id: root

    required property var appearance
    required property var launcherHistory
    property bool enabled: true
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
        property real reveal: root.open ? 1 : 0

        Behavior on reveal {
            NumberAnimation {
                duration: root.appearance.motion.long
                easing.type: root.appearance.motion.easing
            }
        }


        screen: modelData
        visible: root.enabled && reveal > 0 && focusedMonitor
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        focusable: true
        WlrLayershell.namespace: "ndro-shell-application-launcher"
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


        Rectangle {
            anchors.fill: parent
            color: "transparent"

            MouseArea {
                onClicked: launcher.close()
            }
        }

        Rectangle {
            id: launcherCard

            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: -(1 - launcher.reveal) * (height + 32)
            width: Math.min(parent.width - 64, 700)
            height: Math.min(parent.height - 80, 580)
            radius: root.appearance.radius
            color: Qt.rgba(theme.surface.r, theme.surface.g, theme.surface.b, 0.78)
            border.color: theme.border
            border.width: 1

            ApplicationLauncherBody {
                anchors.fill: parent
                anchors.margins: 16
                appearance: root.appearance
                launcherHistory: root.launcherHistory
                active: launcher.visible

                onCloseRequested: launcher.close()
            }
        }
    }
}
