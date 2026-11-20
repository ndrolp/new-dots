import Quickshell.Io
import QtQuick
import "../components/panels" as Panels

// The clipboard history: full-screen, or inside the capsule on a monitor whose
// bar is one (components/panels/ClipboardSelectorPopup.qml).
CapsuleFeature {
    id: root

    required property var appearance
    required property var clipboardHistory
    required property var plugins

    popupName: "clipboard"

    available: plugins.clipboardEnabled

    Panels.ClipboardSelector {
        appearance: root.appearance
        clipboardHistory: root.clipboardHistory
        imagePreviewsEnabled: root.plugins.clipboardImagePreviewsEnabled
        open: root.open

        onCloseRequested: root.open = false
    }

    IpcHandler {
        target: "clipboard"

        function toggle() {
            root.toggle();
        }
    }
}
