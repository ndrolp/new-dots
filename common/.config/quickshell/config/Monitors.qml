import QtQuick
import Quickshell.Io
import "BarProfileModel.js" as BarProfileModel
import "DesktopWidgetsModel.js" as DesktopWidgetsModel

QtObject {
    id: root

    property alias assignments: settings.assignments
    property alias displaySettings: settings.displaySettings

    function rangeFor(monitorName) {
        const assigned = assignments[monitorName];
        const range = assigned !== undefined ? assigned : assignments.default;
        return range !== undefined ? range : { from: 1, to: 5 };
    }

    function workspacesFor(monitorName) {
        const range = rangeFor(monitorName);
        const workspaceIds = [];

        for (let workspaceId = range.from; workspaceId <= range.to; workspaceId++)
            workspaceIds.push(workspaceId);

        return workspaceIds;
    }

    function setRange(monitorName, from, to) {
        const updated = Object.assign({}, assignments);
        updated[monitorName] = {
            from: Math.min(from, to),
            to: Math.max(from, to)
        };
        assignments = updated;
    }

    function setRangeStart(monitorName, from) {
        setRange(monitorName, from, rangeFor(monitorName).to);
    }

    function setRangeEnd(monitorName, to) {
        setRange(monitorName, rangeFor(monitorName).from, to);
    }

    function displaySettingsFor(monitorName) {
        return BarProfileModel.monitorDisplaySettings(displaySettings, monitorName);
    }

    function setDisplaySetting(monitorName, settingName, value) {
        const updated = Object.assign({}, displaySettings);
        const monitorSettings = Object.assign({}, displaySettings[monitorName]);
        monitorSettings[settingName] = value;
        updated[monitorName] = monitorSettings;
        displaySettings = updated;
    }

    // Gives every monitor in `monitorNames` without a bar profile the default
    // one (see BarProfileModel.assignNewMonitor). Skipped until the file is
    // loaded, and after a migration rewrote it until the adapter reloads it,
    // so a stale copy never overwrites it.
    function assignNewMonitors(monitorNames, barProfiles) {
        if (!loaded || reloadPending)
            return;

        let updated = displaySettings;
        for (const monitorName of monitorNames)
            updated = BarProfileModel.assignNewMonitor(updated, monitorName, barProfiles) || updated;

        if (updated !== displaySettings)
            displaySettings = updated;
    }

    function barVisible(monitorName) {
        return displaySettingsFor(monitorName).barVisible;
    }

    // Desktop widgets (incl. the background clock) of a monitor.
    function desktopWidgetsFor(monitorName) {
        return DesktopWidgetsModel.desktopWidgetsFor(displaySettings, monitorName);
    }

    function desktopWidgetOrder(monitorName) {
        return DesktopWidgetsModel.desktopWidgetOrder(desktopWidgetsFor(monitorName));
    }

    function setDesktopWidgetSetting(monitorName, widget, key, value) {
        displaySettings = DesktopWidgetsModel.setDesktopWidgetSetting(
            displaySettings, monitorName, widget, key, value);
    }

    function moveDesktopWidget(monitorName, widget, offset) {
        displaySettings = DesktopWidgetsModel.moveDesktopWidget(
            displaySettings, monitorName, widget, offset);
    }

    function barProfileFor(monitorName) {
        return BarProfileModel.profileForMonitor(displaySettings, monitorName);
    }

    function monitorNames() {
        return Object.keys(assignments).filter(name => name !== "default");
    }

    property bool loaded: false
    property bool reloadPending: false

    // The file as stored, including keys the adapter does not declare.
    function rawState() {
        try {
            return JSON.parse(settingsFile.text());
        } catch (error) {
            return null;
        }
    }

    // Replaces the file with a migrated state in a single write.
    function applyMigratedState(state) {
        reloadPending = true;
        settingsFile.setText(JSON.stringify(state, null, 4));
    }

    property var settingsFile: FileView {
        id: settingsFile

        path: Qt.resolvedUrl("monitors.json")
        atomicWrites: true
        watchChanges: true

        onFileChanged: reload()
        onAdapterUpdated: writeAdapter()
        onLoaded: {
            root.reloadPending = false;
            root.loaded = true;
        }

        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound)
                writeAdapter();
            root.loaded = true;
        }

        adapter: JsonAdapter {
            id: settings

            property var assignments: ({
                "default": { "from": 1, "to": 5 }
            })
            // Every monitor gets its own entry when it first appears.
            property var displaySettings: ({})
        }
    }
}
