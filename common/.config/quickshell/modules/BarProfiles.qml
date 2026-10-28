import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick
import "../config/SchemaMigrations.js" as SchemaMigrations

// Which bar profile each monitor gets: a new monitor gets the default one,
// and IPC or quick settings assign one to the focused monitor.
Scope {
    id: root

    required property var appearance
    required property var monitors
    required property var workspaceService
    required property var osd

    // Assigns a bar profile to the focused monitor.
    function setBarProfile(profileName) {
        root.monitors.setDisplaySetting(root.workspaceService.focusedMonitorDescription(),
            "barProfile", profileName);
        root.osd.showBarProfile(profileName.charAt(0).toUpperCase() + profileName.slice(1));
    }

    // A monitor seen for the first time gets the default bar profile,
    // explicitly, once both files are loaded in the current schema.
    function assignNewMonitors() {
        if (!root.appearance.loaded
                || root.appearance.schemaVersion !== SchemaMigrations.schemaVersion)
            return;

        // Hyprland fills in descriptions after listing a monitor; until then
        // the monitor is not named the way monitors.json names it.
        const names = Hyprland.monitors.values.filter(monitor => monitor.description !== "")
            .map(monitor => monitor.description);
        root.monitors.assignNewMonitors(names, root.appearance.barProfiles);
    }

    Variants {
        model: Hyprland.monitors.values

        delegate: QtObject {
            required property var modelData
            readonly property string description: modelData.description

            onDescriptionChanged: root.assignNewMonitors()
            Component.onCompleted: root.assignNewMonitors()
        }
    }

    Connections {
        target: root.appearance

        function onSchemaVersionChanged() {
            root.assignNewMonitors();
        }

        function onLoadedChanged() {
            root.assignNewMonitors();
        }
    }

    Connections {
        target: root.monitors

        function onLoadedChanged() {
            root.assignNewMonitors();
        }

        function onReloadPendingChanged() {
            root.assignNewMonitors();
        }

        function onDisplaySettingsChanged() {
            root.assignNewMonitors();
        }
    }

    IpcHandler {
        target: "bar-profiles"

        function minimal() {
            root.setBarProfile("minimal");
        }

        function work() {
            root.setBarProfile("work");
        }

        function media() {
            root.setBarProfile("media");
        }

        function presentation() {
            root.setBarProfile("presentation");
        }
    }
}
