import Quickshell.Io
import QtQuick
import "../components/panels" as Panels

Feature {
    id: root

    required property var appearance
    required property var launcherHistory
    required property var plugins

    available: plugins.applicationLauncherEnabled

    Panels.ApplicationLauncher {
        appearance: root.appearance
        launcherHistory: root.launcherHistory
        enabled: root.available
        open: root.open && root.available

        onCloseRequested: root.open = false
    }

    IpcHandler {
        target: "launcher"

        function toggle() {
            root.toggle();
        }
    }
}
