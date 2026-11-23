import Quickshell.Io
import QtQuick
import "../components/panels" as Panels

// The audio output selector: full-screen, or inside the capsule on a monitor
// whose bar is one (components/panels/AudioSinkSelectorPopup.qml). Choosing
// an audio output shows it as a change event.
CapsuleFeature {
    id: root

    required property var appearance
    required property var osd

    popupName: "audioOutputs"

    Panels.AudioSinkSelector {
        appearance: root.appearance
        open: root.open

        onCloseRequested: root.open = false
        onSinkSelected: output => root.osd.showAudioOutput(output)
    }

    IpcHandler {
        target: "audio-sinks"

        function toggle() {
            root.toggle();
        }
    }
}
