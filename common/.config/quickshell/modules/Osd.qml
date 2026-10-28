import Quickshell
import Quickshell.Io
import QtQuick
import "../components/panels" as Panels

// The on-screen display: IPC shows it for the volume and brightness keys, and
// the rest of the shell for audio outputs and bar profiles.
Scope {
    id: root

    required property var appearance

    function showAudioSink(sink) {
        osdPopup.showAudioSink(sink);
    }

    function showBarProfile(name) {
        osdPopup.showBarProfile(name);
    }

    Panels.OsdPopup {
        id: osdPopup

        appearance: root.appearance
    }

    IpcHandler {
        target: "osd"

        function volume() {
            osdPopup.showVolume();
        }

        function brightness() {
            osdPopup.showBrightness();
        }
    }
}
