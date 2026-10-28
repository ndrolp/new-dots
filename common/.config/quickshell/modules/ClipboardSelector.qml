import Quickshell.Io
import QtQuick
import "../components/panels" as Panels

Feature {
    id: root

    required property var appearance
    required property var clipboardHistory
    required property var plugins

    available: plugins.clipboardEnabled

    Panels.ClipboardSelector {
        appearance: root.appearance
        clipboardHistory: root.clipboardHistory
        imagePreviewsEnabled: root.plugins.clipboardImagePreviewsEnabled
        open: root.open && root.available

        onCloseRequested: root.open = false
    }

    IpcHandler {
        target: "clipboard"

        function toggle() {
            root.toggle();
        }
    }
}
