import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import QtQuick

// The full-screen audio output selector (AudioSinkSelectorBody.qml), on the
// focused monitor when its bar is not a capsule (modules/AudioOutputSelector.qml).
Variants {
    id: root

    required property var appearance
    property bool open: false

    signal closeRequested()
    signal sinkSelected(var sink)

    model: Quickshell.screens

    delegate: PanelWindow {
        id: selector

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
        WlrLayershell.namespace: "ndro-shell-audio-sink-selector"
        WlrLayershell.layer: WlrLayer.Overlay

        anchors {
            top: true
            bottom: true
            left: true
            right: true
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

        PopupSurface {
            id: surface

            anchors.centerIn: parent
            width: Math.min(parent.width - 64, 440)
            height: implicitHeight
            open: selector.shown
            enabled: selector.shown
            radius: root.appearance.radius
            motion: root.appearance.motion

            AudioSinkSelectorBody {
                width: parent.width
                appearance: root.appearance
                active: selector.shown

                onCloseRequested: selector.close()
                onSinkSelected: sink => root.sinkSelected(sink)
            }
        }
    }
}
