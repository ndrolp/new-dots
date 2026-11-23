import QtQuick

// The quick search inside a capsule (QuickSearchBody.qml), opened instead of
// the full-screen one on a monitor whose bar is a capsule. The capsule grows
// to its rows of bookmarks. Built only while open: every bar has one.
BarPopup {
    id: root

    // The quick search module (modules/QuickSearch.qml), which holds what it shows.
    required property var feature

    popup: "quickSearch"
    popupWidth: 700

    Loader {
        width: parent.width
        height: item ? item.implicitHeight : 0
        active: root.open || root.reveal > 0

        sourceComponent: QuickSearchBody {
            appearance: root.appearance
            bookmarks: root.feature.bookmarks
            active: root.shown

            onCloseRequested: root.popups.popupClosed(root.popup)
        }
    }
}
