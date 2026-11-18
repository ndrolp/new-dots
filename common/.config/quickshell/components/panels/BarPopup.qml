import QtQuick

// A popup of one bar, open while it is that bar's active one. `popups` is the
// bar's BarPopups, which knows the bar, where its elements are and which
// popup is open.
PopupFrame {
    required property var popups
    // Reported once it is shown, so the bar grows round it (a capsule, a
    // docked zone) as it reveals.
    readonly property var placement: shown ? {
        popup: popup,
        edge: edge,
        start: placedStart,
        end: placedEnd,
        resizing: heldHeight > 0,
        inside: inside,
        width: surfaceWidth,
        height: surfaceHeight,
        windowHeight: implicitHeight
    } : null

    appearance: popups.appearance
    barWindow: popups.barWindow
    anchorProvider: popups.popupAnchorProvider
    open: popups.activePopup === popup
    onDismissed: popups.popupClosed(popup)
    onPlacementChanged: popups.popupPlaced(popup, placement)
}
