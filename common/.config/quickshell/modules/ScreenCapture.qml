import Quickshell.Io
import QtQuick
import "../components/panels" as Panels

// The screenshot and recording chooser; the capturing itself is the
// ScreenCapture service.
Feature {
    id: root

    required property var appearance
    required property var screenCapture
    required property var plugins

    available: plugins.screenCaptureEnabled

    Panels.ScreenCapture {
        appearance: root.appearance
        screenCapture: root.screenCapture
        open: root.open && root.available

        onCloseRequested: root.open = false
    }

    IpcHandler {
        target: "screen-capture"

        function toggle() {
            root.toggle();
        }
    }
}
