import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import QtQuick
import "../../config" as Config

// The full-screen quick search (QuickSearchBody.qml), on the focused monitor
// when its bar is not a capsule (modules/QuickSearch.qml).
Variants {
    id: root

    required property var appearance
    required property var bookmarks
    property bool open: false

    signal closeRequested()

    model: Quickshell.screens

    delegate: PanelWindow {
        id: searchPanel

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
        WlrLayershell.namespace: "ndro-shell-quick-search"
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
                onTapped: searchPanel.close()
            }
        }

        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            width: Math.min(parent.width - 64, 700)
            height: body.implicitHeight + 32
            radius: root.appearance.radius
            color: Qt.rgba(theme.surface.r, theme.surface.g, theme.surface.b, 0.78)
            border.color: theme.border
            border.width: 1

            Behavior on height {
                NumberAnimation {
                    duration: root.appearance.motion.medium
                    easing.type: root.appearance.motion.easing
                }
            }

            QuickSearchBody {
                id: body

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 16
                appearance: root.appearance
                bookmarks: root.bookmarks
                active: searchPanel.visible

                onCloseRequested: searchPanel.close()
            }
        }
    }
}
