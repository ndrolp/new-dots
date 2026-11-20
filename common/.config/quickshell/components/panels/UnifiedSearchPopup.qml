import QtQuick

// Unified search inside a capsule (UnifiedSearchBody.qml), opened instead
// of the full-screen one on a monitor whose bar is a capsule. A result that
// opens another feature closes the popup and opens that one in its place.
// Built only while open: every bar has one.
BarPopup {
    id: root

    // The unified search module (modules/UnifiedSearch.qml), which holds what it shows.
    required property var feature
    readonly property real bodyHeight: 500

    popup: "unifiedSearch"
    popupWidth: 680

    Loader {
        width: parent.width
        height: root.bodyHeight
        active: root.open || root.reveal > 0

        sourceComponent: UnifiedSearchBody {
            appearance: root.appearance
            bookmarks: root.feature.bookmarks
            clipboardHistory: root.feature.clipboardHistory
            monitors: root.feature.monitors
            workspaceService: root.feature.workspaceService
            initialQuery: root.feature.query
            active: root.shown

            onCloseRequested: root.popups.popupClosed(root.popup)
            onSettingsRequested: root.feature.switchTo(root.feature.settings)
            onKeybindCheatsheetRequested: root.feature.switchTo(root.feature.keybindCheatsheet)
            onWebAppMakerRequested: root.feature.switchTo(root.feature.webAppMaker)
            onPrintersRequested: root.feature.switchTo(root.feature.printersPanel)
            onAndroidDevicesRequested: root.feature.switchTo(root.feature.androidDevicesPanel)
        }
    }
}
