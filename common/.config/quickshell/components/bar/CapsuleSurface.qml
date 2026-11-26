import QtQuick
import "CapsuleLook.js" as CapsuleLook
import "CapsuleMotion.js" as CapsuleMotion

// The capsule itself: a round-ended shape in the profile's background colour
// and opacity, behind its row of bar elements, with a soft, tight, faint
// shadow round it, always: the bar border never runs round a capsule. The
// shadow is a few faint rings just outside the shape, fading outwards, so it
// takes its round ends or rounded corners as they morph, never darkens a
// see-through fill, and goes with it when the capsule hides. Expanded it is
// more solid, more opaque with a slightly larger shadow (CapsuleLook.js), on
// the capsule's spring too.
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
    property var spring: CapsuleMotion.springFor(root.appearance.motion, false)
    // Where it is headed: the last place it was given.
    property var target: null
    // Whether it looks expanded (CapsuleLook.looksExpanded): more solid, more
    // opaque with a larger shadow (CapsuleLook.js).
    property bool expanded: false
    // How solid it looks, 0 at rest to 1 expanded, on the capsule's spring:
    // expanding's, overshooting, or collapsing's; at once with reduce motion.
    property real solidity: 0

    onExpandedChanged: {
        const spring = CapsuleMotion.springFor(appearance.motion, expanded);
        solidifying.stop();
        if (spring.duration <= 0) {
            solidity = expanded ? 1 : 0;
            return;
        }
        solidifying.duration = spring.duration;
        solidifying.easing.type = spring.easing;
        solidifying.easing.overshoot = spring.overshoot;
        solidifying.to = expanded ? 1 : 0;
        solidifying.start();
    }

    NumberAnimation {
        id: solidifying

        target: root
        property: "solidity"
    }

    // Springs to `to`, from wherever it is now; jumps there with reduce
    // motion, or across the bar while following a popup.
    function moveTo(to) {
        spring = target ? CapsuleMotion.spring(appearance.motion, target, to)
            : CapsuleMotion.springFor(appearance.motion, false);
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
    // pixels, faint and fading, a little larger as it is more solid.
    readonly property var shadowRings: CapsuleLook.shadowRings(solidity)

    Repeater {
        // As many rings as there are, so they stay put while they darken.
        model: root.width > 0 && root.height > 0 ? root.shadowRings.length : 0

        Rectangle {
            required property int index
            readonly property int reach: index + 1

            x: -reach
            y: -reach
            width: root.width + reach * 2
            height: root.height + reach * 2
            radius: root.drawnRadius + reach
            color: "transparent"
            border.width: 1
            border.color: Qt.rgba(0, 0, 0, root.shadowRings[index])
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: root.drawnRadius
        color: Qt.rgba(root.fillColor.r, root.fillColor.g, root.fillColor.b,
            CapsuleLook.fillAlpha(root.fillColor.a, root.solidity))
    }
}
