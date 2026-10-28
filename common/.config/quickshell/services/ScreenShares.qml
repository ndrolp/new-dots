import Quickshell
import Quickshell.Services.Pipewire
import QtQuick
import "../components/bar/RecordingIndicator.js" as RecordingIndicator

// The screens other apps share through PipeWire, with when each was first
// seen. The shell owns the one instance, so the graph is read and the start
// times kept once, not in every bar. What counts as a shared screen is
// decided in RecordingIndicator.js (screenShares, startTimes).
Scope {
    id: root

    // The shares read from the graph, as `{ id, app }`.
    readonly property var current: RecordingIndicator.screenShares(
        Pipewire.nodes.values.map(node => ({ id: node.id, isStream: node.isStream, properties: node.properties })),
        Pipewire.linkGroups.values.filter(link => link.source && link.target)
            .map(link => ({ source: link.source.id, target: link.target.id })))
    // The same shares as `{ id, app, startedAt }` (RecordingIndicator.recordings).
    property var shares: []

    onCurrentChanged: shares = RecordingIndicator.startTimes(shares, current, Date.now())

    // Node properties are only read while tracked; screen shares need them.
    PwObjectTracker {
        objects: Pipewire.nodes.values
    }
}
