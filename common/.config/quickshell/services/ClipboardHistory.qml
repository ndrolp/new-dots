import Quickshell.Io
import QtQuick

QtObject {
    id: root

    property var entries: []
    property alias pinnedIds: settings.pinnedIds
    readonly property bool busy: historyMutation.running
    readonly property var orderedEntries: {
        const pinned = [];
        const unpinned = [];

        for (const entry of entries) {
            if (isPinned(entry.id))
                pinned.push(entry);
            else
                unpinned.push(entry);
        }

        return pinned.concat(unpinned);
    }

    function isPinned(id) {
        const numericId = Number(id);
        return Number.isInteger(numericId)
            && pinnedIds.some(pinnedId => Number(pinnedId) === numericId);
    }

    function togglePinned(id) {
        const numericId = Number(id);

        if (!Number.isInteger(numericId))
            return;

        const updated = pinnedIds.filter(pinnedId => Number(pinnedId) !== numericId);
        pinnedIds = isPinned(numericId) ? updated : [numericId].concat(updated);
    }

    function deleteEntry(id) {
        const numericId = Number(id);

        if (busy || !Number.isInteger(numericId)
                || !entries.some(entry => entry.id === numericId))
            return;

        if (isPinned(numericId))
            togglePinned(numericId);

        entries = entries.filter(entry => entry.id !== numericId);
        deleteEntries([numericId]);
    }

    function clearNonPinned() {
        if (busy)
            return;

        const ids = entries.filter(entry => !isPinned(entry.id)).map(entry => entry.id);

        if (ids.length === 0)
            return;

        entries = entries.filter(entry => isPinned(entry.id));
        deleteEntries(ids);
    }

    function deleteEntries(ids) {
        if (ids.length === 0)
            return;

        historyMutation.command = [
            "sh", "-c",
            "printf '%s\\n' \"$@\" | cliphist delete",
            "cliphist-delete"
        ].concat(ids.map(id => String(id)));
        historyMutation.running = true;
    }

    function refresh() {
        if (!historyQuery.running) {
            entries = [];
            historyQuery.running = true;
        }
    }

    function addEntry(line) {
        const separator = line.indexOf("\t");

        if (separator <= 0)
            return;

        const id = Number(line.slice(0, separator));
        if (!Number.isInteger(id))
            return;

        entries = entries.concat([{
            id: id,
            preview: line.slice(separator + 1),
            image: line.includes("[[ binary data")
        }]);
    }

    property var historyMutation: Process {
        id: historyMutation

        onExited: root.refresh()
    }

    property var historyQuery: Process {
        id: historyQuery

        command: ["cliphist", "list"]

        stdout: SplitParser {
            onRead: data => root.addEntry(data)
        }
    }

    property var settingsFile: FileView {
        id: settingsFile

        path: Qt.resolvedUrl("../config/clipboard.json")
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

            property var pinnedIds: []
        }
    }
}
