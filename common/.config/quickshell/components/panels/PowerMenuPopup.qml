import QtQuick

// The power menu inside a capsule (PowerMenuBody.qml), opened instead of the
// full-screen one on a monitor whose bar is a capsule: one row of its five
// actions. Built only while open: every bar has one.
BarPopup {
    id: root

    // The power menu module (modules/PowerMenu.qml).
    required property var feature

    popup: "powerMenu"
    popupWidth: 520

    Loader {
        width: parent.width
        height: item ? item.implicitHeight : 0
        active: root.open || root.reveal > 0

        sourceComponent: PowerMenuBody {
            appearance: root.appearance
            active: root.shown

            onCloseRequested: root.popups.popupClosed(root.popup)
        }
    }
}
