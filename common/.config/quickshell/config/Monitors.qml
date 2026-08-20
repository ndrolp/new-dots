import QtQuick
import Quickshell.Io

QtObject {
    id: root

    property alias assignments: settings.assignments

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

    function monitorNames() {
        return Object.keys(assignments).filter(name => name !== "default");
    }

    property var settingsFile: FileView {
        id: settingsFile

        path: Qt.resolvedUrl("monitors.json")
        atomicWrites: true
        watchChanges: true

        onFileChanged: reload()
        onAdapterUpdated: writeAdapter()

        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound)
                writeAdapter();
        }

        adapter: JsonAdapter {
            id: settings

            property var assignments: ({
                "default": { "from": 1, "to": 5 }
            })
        }
    }
}
