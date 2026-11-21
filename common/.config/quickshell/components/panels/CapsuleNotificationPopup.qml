import QtQuick
import "." as Panels

// A new notification inside the capsule, with notifications in the capsule
// on: the same card as a toast (NewNotificationCard), in the capsule past its
// row as a popup inside it is, and the "+N" of the ones waiting. It shows while no
// other popup is inside; the capsule hands its notifications back as toasts
// before one opens. It takes no focus, so it doesn't take the keyboard, until
// its inline reply is written.
PopupFrame {
    id: root

    required property var popups
    // The notification shown (CapsuleNotificationQueue), or null.
    property var notification: null
    // How many more wait behind it.
    property int waiting: 0
    // The last one shown, which stays on the card as it hides.
    property var lastNotification: null
    // Reported once it is shown, so the capsule grows round it as it reveals.
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

    // Its card is done with (CapsuleNotificationQueue.ended).
    signal ended(var notification)

    onNotificationChanged: {
        if (notification !== null)
            lastNotification = notification;
    }

    popup: "capsuleNotification"
    popupWidth: 380
    appearance: popups.appearance
    barWindow: popups.barWindow
    anchorProvider: popups.popupAnchorProvider
    open: notification !== null && popups.activePopup === ""
    grabsFocus: card.replying
    // A click outside while a reply is written leaves the reply.
    onDismissed: card.stopReplying()
    onPlacementChanged: popups.popupPlaced(popup, placement)

    Panels.NewNotificationCard {
        id: card

        width: parent.width
        appearance: root.appearance
        notification: root.lastNotification
        waiting: root.waiting
        framed: false
        running: root.open
        onEnded: root.ended(root.notification)
    }
}
