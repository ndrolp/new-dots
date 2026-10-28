import Quickshell.Io
import QtQuick
import "../components/panels" as Panels

Feature {
    id: root

    required property var appearance
    required property var plugins

    available: plugins.commandLauncherEnabled

    Panels.CommandLauncher {
        appearance: root.appearance
        open: root.open

        onCloseRequested: root.open = false
    }

    IpcHandler {
        target: "command-launcher"

        function toggle() {
            root.toggle();
        }
    }
}
