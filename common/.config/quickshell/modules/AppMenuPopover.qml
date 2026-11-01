import Quickshell.Io
import QtQuick
import "../components/panels" as Panels

// The app menu popover (SUPER+A): the focused app's menus at the cursor.
Feature {
    id: root

    required property var appearance
    // The app menu's bridge to apps' own menus (services/AppMenuBridge.qml).
    required property var appMenuBridge

    Panels.AppMenuPopover {
        appearance: root.appearance
        bridge: root.appMenuBridge
        open: root.open

        onCloseRequested: root.open = false
    }

    IpcHandler {
        target: "app-menu"

        function toggle() {
            root.toggle();
        }
    }
}
