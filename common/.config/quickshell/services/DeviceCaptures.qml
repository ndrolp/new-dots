import Quickshell
import Quickshell.Services.Pipewire
import QtQuick
import "../components/bar/PrivacyIndicator.js" as PrivacyIndicator

// The apps using the microphone or a camera, read from PipeWire the way
// ScreenShares.qml reads screen shares, for the privacy indicator. The shell
// owns the one instance, so the graph is read once, not in every bar. What
// counts as using a device is decided in PrivacyIndicator.js (captures).
Scope {
    // { microphone: [apps], camera: [apps] } (PrivacyIndicator.captures).
    readonly property var captures: PrivacyIndicator.captures(
        Pipewire.nodes.values.map(node => ({ id: node.id, isStream: node.isStream, properties: node.properties })),
        Pipewire.linkGroups.values.filter(link => link.source && link.target)
            .map(link => ({ source: link.source.id, target: link.target.id })))

    // Node properties are only read while tracked; the captures need them.
    PwObjectTracker {
        objects: Pipewire.nodes.values
    }
}
