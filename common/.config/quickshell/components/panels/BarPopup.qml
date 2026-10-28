import QtQuick

// A popup of one bar, open while it is that bar's active one. `popups` is the
// bar's BarPopups, which knows the bar, where its elements are and which
// popup is open.
PopupFrame {
    required property var popups

    appearance: popups.appearance
    barWindow: popups.barWindow
    anchorProvider: popups.popupAnchorProvider
    open: popups.activePopup === popup
    onDismissed: popups.popupClosed(popup)
}
