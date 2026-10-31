import QtQuick
import "../../config" as Config
import "." as Panels
import "NotificationCard.js" as NotificationCard

// A notification card: one notification in the control center, Android
// style. Tapping it runs its default action, then it is removed and the
// control center closes; one without a default action expands instead.
// Swiping it sideways past the threshold dismisses it.
// `entry` is a NotificationHistory item; its `notification` is the live
// Quickshell Notification, or null once the server has let it go.
Item {
    id: root

    required property var appearance
    required property var entry

    readonly property var actions: entry.notification ? entry.notification.actions : []
    // Showing the full body.
    property bool expanded: false
    // How far the card has been dragged sideways.
    property alias swipeOffset: face.x

    // The card is done with: remove it from the history.
    signal dismissed()
    // The control center should close (a default action ran).
    signal closeRequested()

    objectName: "notificationCard"
    implicitHeight: face.height

    // A tap on the card, from its TapHandler.
    function tap() {
        const action = NotificationCard.defaultAction(root.actions);
        if (action) {
            action.invoke();
            root.dismissed();
            root.closeRequested();
        } else {
            root.expanded = !root.expanded;
        }
    }

    // Letting go of a sideways drag: past the threshold the card slides out
    // and is dismissed, otherwise it snaps back.
    function swipeReleased() {
        if (NotificationCard.swipeDismisses(face.x, root.width)) {
            swipeOut.to = face.x < 0 ? -root.width : root.width;
            swipeOut.restart();
        } else {
            snapBack.restart();
        }
    }

    NumberAnimation {
        id: swipeOut

        target: face
        property: "x"
        duration: root.appearance.motion.medium
        easing.type: root.appearance.motion.easing
        onFinished: root.dismissed()
    }

    NumberAnimation {
        id: snapBack

        target: face
        property: "x"
        to: 0
        duration: root.appearance.motion.medium
        easing.type: root.appearance.motion.easing
    }

    Item {
        id: face

        width: root.width
        height: 70
        opacity: 1 - Math.min(1, Math.abs(x) / Math.max(1, root.width)) * 0.8

        DragHandler {
            target: face
            xAxis.enabled: true
            yAxis.enabled: false
            onActiveChanged: {
                if (!active)
                    root.swipeReleased();
            }
        }

        TapHandler {
            onTapped: root.tap()
        }
    }
}
