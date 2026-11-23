import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import QtQuick
import "../../config" as Config

// The full-screen power menu (PowerMenuBody.qml), on the focused monitor when
// its bar is not a capsule (modules/PowerMenu.qml).
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

        function close() {
            root.closeRequested();
        }

        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(theme.background.r, theme.background.g, theme.background.b, 0.7)
            opacity: surface.reveal

            TapHandler {
                onTapped: menu.close()
            }
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

            PowerMenuBody {
                width: parent.width
                appearance: root.appearance
                active: menu.shown

                onCloseRequested: menu.close()
            }
        }
    }
}
