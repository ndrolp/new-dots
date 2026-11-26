import QtQuick
import "CapsuleMotion.js" as CapsuleMotion

// The capsule itself: a round-ended shape in the profile's background colour
// and opacity, behind its row of bar elements, with a soft, tight, faint
// shadow round it, always: the bar border never runs round a capsule. The
// shadow is a few faint rings just outside the shape, fading outwards, so it
// takes its round ends or rounded corners as they morph, never darkens a
// see-through fill, and goes with it when the capsule hides.
// It slides and stretches along the bar as the row
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

    // One of its place's numbers moving to where it is headed on the spring.
    component Spring: NumberAnimation {
        target: root
        to: root.target ? root.target[property] : 0
        duration: root.spring.duration
        easing.type: root.spring.easing
        easing.overshoot: root.spring.overshoot
    }

    ParallelAnimation {
        id: motion

        Spring { property: "x" }
        Spring { property: "y" }
        Spring { property: "width" }
        Spring { property: "height" }
        Spring { property: "radius" }
    }

    // Its corner radius as drawn: never rounder than its ends, mid-overshoot
    // included.
    readonly property real drawnRadius: Math.max(0, Math.min(radius, width / 2, height / 2))
    // How dark each ring of its shadow is, from its edge outwards: a few
    // pixels, faint and fading.
    readonly property var shadowRings: [0.14, 0.09, 0.05, 0.02]

    Repeater {
        model: root.width > 0 && root.height > 0 ? root.shadowRings : []

        Rectangle {
            required property int index
            required property real modelData
            readonly property int reach: index + 1

            x: -reach
            y: -reach
            width: root.width + reach * 2
            height: root.height + reach * 2
            radius: root.drawnRadius + reach
            color: "transparent"
            border.width: 1
            border.color: Qt.rgba(0, 0, 0, modelData)
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: root.drawnRadius
        color: root.fillColor
    }
}
