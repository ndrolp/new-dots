import Quickshell.Io
import QtQuick
import "../components/panels" as Panels

// Opened by cycling through windows over IPC, not toggled.
Feature {
    id: root

    required property var appearance
    required property var workspaceService

    Panels.WindowSwitcher {
        id: windowSwitcher

        appearance: root.appearance
        workspaceService: root.workspaceService
        open: root.open

        onOpenRequested: root.open = true
        onCloseRequested: root.open = false
    }

    IpcHandler {
        target: "window-switcher"

        function next() {
            windowSwitcher.cycle(1);
        }

        function previous() {
            windowSwitcher.cycle(-1);
        }

        function close() {
            root.open = false;
        }
    }
}
