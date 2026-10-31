import QtQuick
import "NotificationCard.js" as NotificationCard

// Swiping a notification card (or a collapsed app stack) sideways to
// dismiss it: drags `target` along x; letting go past the threshold
// (NotificationCard.swipeDismisses) slides it out and emits `swiped()`,
// a shorter drag snaps it back. `swipeOpacity` fades it as it goes.
DragHandler {
    id: root

    // The bar appearance's motion (durations, easing).
    required property var motion
    // The width of what is swiped: the threshold and the slide-out distance.
    property real swipeWidth: 0
    readonly property real swipeOpacity: 1 - Math.min(1,
        Math.abs(target ? target.x : 0) / Math.max(1, swipeWidth)) * 0.8

    // It slid out: the owner dismisses it.
    signal swiped()

    // Letting go of the drag (the tests call it after setting target.x).
    function letGo() {
        if (NotificationCard.swipeDismisses(target.x, swipeWidth)) {
            slideOut.to = target.x < 0 ? -swipeWidth : swipeWidth;
            slideOut.restart();
        } else {
            snapBack.restart();
        }
    }

    property NumberAnimation slideOut: NumberAnimation {
        target: root.target
        property: "x"
        duration: root.motion.medium
        easing.type: root.motion.easing
        onFinished: root.swiped()
    }

    property NumberAnimation snapBack: NumberAnimation {
        target: root.target
        property: "x"
        to: 0
        duration: root.motion.medium
        easing.type: root.motion.easing
    }

    xAxis.enabled: true
    yAxis.enabled: false
    onActiveChanged: {
        if (!active)
            letGo();
    }
}
