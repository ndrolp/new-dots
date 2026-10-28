import Quickshell.Io
import QtQuick
import "../components/panels" as Panels

Feature {
    id: root

    required property var appearance

    Panels.ThemeSelector {
        appearance: root.appearance
        open: root.open

        onCloseRequested: root.open = false
    }

    IpcHandler {
        target: "themes"

        function toggle() {
            root.toggle();
        }
    }
}
