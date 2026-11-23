import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import QtQuick
import "../../config" as Config

// The full-screen colorscheme selector (ThemeSelectorBody.qml), on the focused
// monitor when its bar is not a capsule (modules/ThemeSelector.qml).
Variants {
    id: root

    required property var appearance
    // The wallpapers (config/Wallpapers.qml): each colorscheme's own is shown.
    property var wallpapers: null
    property bool open: false

    signal closeRequested()

    model: Quickshell.screens

    delegate: PanelWindow {
        id: selector

        required property var modelData
        readonly property var monitor: Hyprland.monitorFor(modelData)
        readonly property bool focusedMonitor: Hyprland.focusedWorkspace
            && Hyprland.focusedWorkspace.monitor && monitor
            && Hyprland.focusedWorkspace.monitor.name === monitor.name

        screen: modelData
        visible: root.open && focusedMonitor
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        focusable: true
        WlrLayershell.namespace: "ndro-shell-theme-selector"
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

            TapHandler {
                onTapped: selector.close()
            }
        }

        Rectangle {
            anchors.centerIn: parent
            width: Math.min(parent.width - 64, 640)
            height: body.implicitHeight + 32
            radius: 12
            color: Qt.rgba(theme.surface.r, theme.surface.g, theme.surface.b, 0.88)
            border.color: theme.border
            border.width: 1

            ThemeSelectorBody {
                id: body

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 16
                appearance: root.appearance
                wallpapers: root.wallpapers
                active: selector.visible

                onCloseRequested: selector.close()
            }
        }
    }
}
