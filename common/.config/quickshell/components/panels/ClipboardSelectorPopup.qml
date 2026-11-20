import QtQuick

// The clipboard history inside a capsule (ClipboardSelectorBody.qml),
// opened instead of the full-screen one on a monitor whose bar is a capsule.
// Built only while open: every bar has one.
BarPopup {
    id: root

    // The clipboard module (modules/ClipboardSelector.qml), which holds what it shows.
    required property var feature
    readonly property real bodyHeight: 420

    popup: "clipboard"
    popupWidth: 560

    Loader {
        width: parent.width
        height: root.bodyHeight
        active: root.open || root.reveal > 0

        sourceComponent: ClipboardSelectorBody {
            appearance: root.appearance
            clipboardHistory: root.feature.clipboardHistory
            imagePreviewsEnabled: root.feature.plugins.clipboardImagePreviewsEnabled
            active: root.shown

            onCloseRequested: root.popups.popupClosed(root.popup)
        }
    }
}
