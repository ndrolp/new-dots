import Quickshell.Io
import QtQuick
import "../components/panels" as Panels

Feature {
    id: root

    required property var appearance
    required property var monitors
    required property var workspaceService

    Panels.WorkspaceOverview {
        appearance: root.appearance
        monitors: root.monitors
        workspaceService: root.workspaceService
        open: root.open

        onCloseRequested: root.open = false
    }

    IpcHandler {
        target: "workspace-overview"

        function toggle() {
            root.toggle();
        }
    }
}
