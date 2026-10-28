import Quickshell.Io
import QtQuick
import "../components/panels" as Panels

Feature {
    id: root

    required property var appearance
    required property var osd

    Panels.AudioSinkSelector {
        appearance: root.appearance
        open: root.open

        onCloseRequested: root.open = false
        onSinkSelected: sink => root.osd.showAudioSink(sink)
    }

    IpcHandler {
        target: "audio-sinks"

        function toggle() {
            root.toggle();
        }
    }
}
