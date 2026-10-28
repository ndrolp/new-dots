import Quickshell.Io
import QtQuick
import "../components/panels" as Panels

Feature {
    id: root

    required property var appearance
    required property var bookmarks
    required property var clipboardHistory
    required property var monitors
    required property var workspaceService
    required property var plugins
    // The features its results open.
    required property var settings
    required property var keybindCheatsheet

    // What the search field holds when it opens.
    property string query: ""

    available: plugins.unifiedSearchEnabled

    Panels.UnifiedSearch {
        appearance: root.appearance
        bookmarks: root.bookmarks
        clipboardHistory: root.clipboardHistory
        monitors: root.monitors
        workspaceService: root.workspaceService
        open: root.open && root.available
        initialQuery: root.query

        onCloseRequested: root.open = false
        onSettingsRequested: root.switchTo(root.settings)
        onKeybindCheatsheetRequested: root.switchTo(root.keybindCheatsheet)
    }

    IpcHandler {
        target: "unified-search"

        function toggle() {
            if (!root.available)
                return;

            root.query = "";
            root.open = !root.open;
        }

        // Opens search on the emoji picker, ":" already typed.
        function emoji() {
            if (!root.available)
                return;

            const close = root.open && root.query === ":";
            root.query = ":";
            root.open = !close;
        }
    }
}
