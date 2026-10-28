import Quickshell.Io
import QtQuick
import "../components/panels" as Panels

Feature {
    id: root

    required property var appearance
    required property var bookmarks
    required property var plugins

    available: plugins.quickSearchEnabled

    Panels.QuickSearch {
        appearance: root.appearance
        bookmarks: root.bookmarks
        open: root.open && root.available

        onCloseRequested: root.open = false
    }

    IpcHandler {
        target: "quick-search"

        function toggle() {
            root.toggle();
        }
    }
}
