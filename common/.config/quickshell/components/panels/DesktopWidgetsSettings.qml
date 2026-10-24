import QtQuick
import Quickshell.Hyprland
import "." as Panels

// The Desktop Widgets section: a segmented choice of the connected monitors,
// then the desktop widgets of the chosen one.
Column {
    id: root

    property var appearance
    property var monitors

    width: parent ? parent.width : 0
    spacing: 14

    readonly property var connectedMonitors: Hyprland.monitors.values
    property string selectedMonitor: ""

    function connectedMonitorNames() {
        const names = [];

        for (let index = 0; index < connectedMonitors.length; index++) {
            if (connectedMonitors[index].description !== "")
                names.push(connectedMonitors[index].description);
        }

        return names;
    }

    function ensureSelectedMonitor() {
        const names = connectedMonitorNames();

        if (names.indexOf(selectedMonitor) === -1)
            selectedMonitor = names.length > 0 ? names[0] : "";
    }

    Component.onCompleted: ensureSelectedMonitor()

    Connections {
        target: Hyprland.monitors

        function onValuesChanged() {
            root.ensureSelectedMonitor();
        }
    }

    Panels.SettingsChoice {
        width: parent.width
        appearance: root.appearance
        options: root.connectedMonitorNames().map(name => ({ label: name, value: name }))
        value: root.selectedMonitor
        onChosen: name => root.selectedMonitor = name
    }

    Panels.SettingsHint {
        width: parent.width
        appearance: root.appearance
        text: "Turn a desktop widget on, then choose where it appears on this monitor's desktop."
    }

    Panels.DesktopWidgetsMonitorSettings {
        appearance: root.appearance
        monitors: root.monitors
        monitorName: root.selectedMonitor
    }
}
