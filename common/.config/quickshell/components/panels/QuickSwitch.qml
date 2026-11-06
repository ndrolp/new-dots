import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import QtQuick
import "." as Panels

// The quick switch's window: a small centred panel on the focused monitor.
Variants {
    id: root

    required property var appearance
    property bool open: false
    property var choices: []
    property int currentIndex: 0

    signal closeRequested()
    signal selectionAsked(int index)
    signal chosen(var choice)

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
        WlrLayershell.namespace: "ndro-shell-quick-switch"
        WlrLayershell.layer: WlrLayer.Overlay

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        onVisibleChanged: {
            if (visible)
                list.forceActiveFocus();
        }

        Rectangle {
            anchors.fill: parent
            color: "transparent"

            TapHandler {
                onTapped: root.closeRequested()
            }
        }

        Panels.PopupSurface {
            id: surface

            anchors.centerIn: parent
            width: Math.min(parent.width - 64, 380)
            height: implicitHeight
            open: selector.shown
            radius: root.appearance.radius
            motion: root.appearance.motion

            Panels.QuickSwitchList {
                id: list

                width: parent.width
                focus: selector.shown
                appearance: root.appearance
                choices: root.choices
                currentIndex: root.currentIndex
                onSelectionAsked: index => root.selectionAsked(index)
                onChosen: choice => root.chosen(choice)
                onCloseAsked: root.closeRequested()
            }
        }
    }
}
