import QtQuick
import "CapsuleMotion.js" as CapsuleMotion

// The capsule itself: a round-ended shape in the profile's background colour
// and opacity, behind its row of bar elements, with the bar border around it
// when that setting is on. It slides and stretches along the bar as the row
// changes, and grows and shrinks across it as a popup inside opens, closes or
// resizes, on the capsule's springs (Motion.js `capsule`, picked by
// CapsuleMotion.spring): growing overshoots slightly and settles, shrinking
// is a bit faster without bounce. Its corners morph on the same spring, from
// a full pill at rest to a rounded rectangle round a popup and back
// (CapsulePlacement.withPopup). Reduce motion moves it at once.
Item {
    id: root

    // Where it sits and its size, as CapsulePlacement.surface gives it.
    required property var place
    required property color fillColor
    // Whether the bar border runs around it.
    property bool border: false
    property color borderColor: "transparent"
    // The bar's appearance, for its Bar position and motion.
    required property var appearance
    // Whether a popup inside is resizing itself in its own animation, which
    // the capsule then follows frame by frame across the bar instead of
    // animating again.
    property bool following: false
    // Its corner radius as drawn, morphing with its size.
    property real radius: 0
    // The spring it moves on now (CapsuleMotion.spring).
    property var spring: root.appearance.motion.capsule.collapse
    // Where it is headed: the last place it was given.
    property var target: null

    // Springs to `to`, from wherever it is now; jumps there with reduce
    // motion, or across the bar while following a popup.
    function moveTo(to) {
        spring = target ? CapsuleMotion.spring(appearance.motion, target, to) : appearance.motion.capsule.collapse;
        target = to;
        motion.stop();
        if (following) {
            y = to.y;
            height = to.height;
        }
        if (spring.duration <= 0) {
            x = to.x;
            y = to.y;
            width = to.width;
            height = to.height;
            radius = to.radius;
            return;
        }
        motion.start();
    }

    onPlaceChanged: moveTo(place)
    Component.onCompleted: {
        x = place.x;
        y = place.y;
        width = place.width;
        height = place.height;
        radius = place.radius;
        target = place;
    }

    ParallelAnimation {
        id: motion

        NumberAnimation {
            target: root; property: "x"; to: root.target ? root.target.x : 0
            duration: root.spring.duration; easing.type: root.spring.easing; easing.overshoot: root.spring.overshoot
        }
        NumberAnimation {
            target: root; property: "y"; to: root.target ? root.target.y : 0
            duration: root.spring.duration; easing.type: root.spring.easing; easing.overshoot: root.spring.overshoot
        }
        NumberAnimation {
            target: root; property: "width"; to: root.target ? root.target.width : 0
            duration: root.spring.duration; easing.type: root.spring.easing; easing.overshoot: root.spring.overshoot
        }
        NumberAnimation {
            target: root; property: "height"; to: root.target ? root.target.height : 0
            duration: root.spring.duration; easing.type: root.spring.easing; easing.overshoot: root.spring.overshoot
        }
        NumberAnimation {
            target: root; property: "radius"; to: root.target ? root.target.radius : 0
            duration: root.spring.duration; easing.type: root.spring.easing; easing.overshoot: root.spring.overshoot
        }
    }

    Rectangle {
        anchors.fill: parent
        // Never rounder than its ends, mid-overshoot included.
        radius: Math.max(0, Math.min(root.radius, root.width / 2, root.height / 2))
        color: root.fillColor
        border.width: root.border ? 1 : 0
        border.color: root.border ? root.borderColor : "transparent"
    }
}
