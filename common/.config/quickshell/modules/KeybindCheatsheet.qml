import Quickshell.Io
import QtQuick
import "../components/panels" as Panels

Feature {
    id: root

    required property var appearance

    Panels.KeybindCheatsheet {
        appearance: root.appearance
        open: root.open

        onCloseRequested: root.open = false
    }

    IpcHandler {
        target: "keybinds"

        function toggle() {
            root.toggle();
        }
    }
}
