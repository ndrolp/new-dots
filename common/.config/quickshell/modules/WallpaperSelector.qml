import Quickshell.Io
import QtQuick
import "../components/panels" as Panels

Feature {
    id: root

    required property var appearance
    required property var wallpapers

    Panels.WallpaperSelector {
        appearance: root.appearance
        wallpapers: root.wallpapers
        open: root.open

        onCloseRequested: root.open = false
    }

    IpcHandler {
        target: "wallpapers"

        function toggle() {
            root.toggle();
        }

        // Opens it, or leaves it open (the app menu's Desktop menu).
        function show() {
            root.show();
        }
    }
}
