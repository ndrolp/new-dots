import Quickshell.Hyprland
import Quickshell
import QtQuick
import "." as Panels

// The Displays section: each connected monitor's settings, one after another.
Column {
    id: root

    required property var appearance
    property var monitors
    width: parent ? parent.width : 0
    spacing: 28

    function monitorDescriptionForScreen(screen) {
        const monitor = Hyprland.monitorFor(screen);
        return monitor !== null && monitor.description !== "" ? monitor.description : screen.name;
    }

    Repeater {
        model: Quickshell.screens

        delegate: Panels.MonitorDisplaySettings {
            required property var modelData

            appearance: root.appearance
            monitors: root.monitors
            monitorDescription: root.monitorDescriptionForScreen(modelData)
            visible: monitorDescription !== ""
        }
    }
}
