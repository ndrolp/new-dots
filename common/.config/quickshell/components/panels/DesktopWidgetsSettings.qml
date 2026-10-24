import QtQuick
import "." as Panels

// The Desktop Widgets section: a segmented choice of the connected monitors,
// then the desktop widgets of the chosen one.
Column {
    id: root

    required property var appearance
    property var monitors

    width: parent ? parent.width : 0
    spacing: 14

    property string selectedMonitor: ""

    Panels.ConnectedDisplays {
        id: connectedDisplays
    }

    Panels.SettingsMonitorChoice {
        width: parent.width
        appearance: root.appearance
        displays: connectedDisplays.values
        value: root.selectedMonitor
        onChosen: description => root.selectedMonitor = description
    }

    Panels.SettingsHint {
        width: parent.width
        appearance: root.appearance
        text: "Enable a widget, then choose where it appears on this monitor's desktop."
    }

    Panels.DesktopWidgetsMonitorSettings {
        appearance: root.appearance
        monitors: root.monitors
        monitorName: root.selectedMonitor
    }
}
