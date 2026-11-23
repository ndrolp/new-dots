import Quickshell.Io
import QtQuick
import "../components/panels" as Panels

// The quick search: full-screen, or inside the capsule on a monitor whose
// bar is one (components/panels/QuickSearchPopup.qml).
CapsuleFeature {
    id: root

    required property var appearance
    required property var bookmarks
    required property var plugins

    popupName: "quickSearch"

    available: plugins.quickSearchEnabled

    Panels.QuickSearch {
        appearance: root.appearance
        bookmarks: root.bookmarks
        open: root.open

        onCloseRequested: root.open = false
    }

    IpcHandler {
        target: "quick-search"

        function toggle() {
            root.toggle();
        }
    }
}
