import Quickshell
import Quickshell.Io
import QtQuick
import "../components/panels" as Panels

// The on-screen display: IPC shows it for the volume and brightness keys, and
// the rest of the shell for audio outputs, bar profiles and the keep-awake
// keybind.
Scope {
    id: root

    required property var appearance

    function showAudioOutput(output) {
        osdPopup.showAudioSink(output);
    }

    function showBarProfile(name) {
        osdPopup.showBarProfile(name);
    }

    function showKeepAwake(on, duration) {
        osdPopup.showKeepAwake(on, duration);
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
