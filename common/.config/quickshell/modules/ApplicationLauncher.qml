import Quickshell.Io
import QtQuick
import "../components/panels" as Panels

// The application launcher: full-screen, or inside the capsule on a monitor
// whose bar is one (components/panels/ApplicationLauncherPopup.qml).
CapsuleFeature {
    id: root

    required property var appearance
    required property var launcherHistory
    required property var plugins

    popupName: "launcher"

    available: plugins.applicationLauncherEnabled

    Panels.ApplicationLauncher {
        appearance: root.appearance
        launcherHistory: root.launcherHistory
        enabled: root.available
        open: root.open

        onCloseRequested: root.open = false
    }

    IpcHandler {
        target: "launcher"

        function toggle() {
            root.toggle();
        }
    }
}
