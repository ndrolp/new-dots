import QtQuick
import QtTest
import "../components/bar"
import "../config/Motion.js" as Motion

// The capsule is drawn in the profile's background colour and opacity, with
// a soft shadow round it, always, and never the bar border.
TestCase {
    name: "CapsuleSurface"
    width: 300
    height: 100
    visible: true
    when: windowShown

    Component {
        id: area

        Rectangle {
            property alias surface: surface

            width: 300
            height: 100
            color: "#ffffff"

            CapsuleSurface {
                id: surface

                place: ({ x: 50, y: 20, width: 200, height: 40, radius: 20 })
                fillColor: "#ff0000"
                appearance: ({ barPosition: "top", motion: Motion.motion(true) })
            }
        }
    }

    function colorAt(item, x, y) {
        const pixel = grabImage(item).pixel(x, y);
        return { r: Math.round(pixel.r), g: Math.round(pixel.g), b: Math.round(pixel.b) };
    }

    function test_theCapsuleSitsWhereItIsPlaced() {
        const built = createTemporaryObject(area, this);

        compare(built.surface.x, 50);
        compare(built.surface.y, 20);
        compare(built.surface.width, 200);
        compare(built.surface.height, 40);
        compare(built.surface.radius, 20);
    }

    function test_theCapsuleIsFilledWithItsColor() {
        const built = createTemporaryObject(area, this);

        compare(colorAt(built, 150, 40), { r: 1, g: 0, b: 0 });
    }

    // Round ends: the corners of its box stay clear.
    function test_theCapsulesEndsAreRound() {
        const built = createTemporaryObject(area, this);

        compare(colorAt(built, 51, 21), { r: 1, g: 1, b: 1 });
    }

    // Right at its edge it is its own colour: no line runs round it.
    function test_noBorderRunsAroundTheCapsule() {
        const built = createTemporaryObject(area, this);

        compare(colorAt(built, 150, 20), { r: 1, g: 0, b: 0 });
        compare(colorAt(built, 150, 59), { r: 1, g: 0, b: 0 });
    }

    // How dark the desktop is under a pixel of the area, 0 untouched to 1
    // black: what the shadow adds there.
    function shadeAt(item, x, y) {
        const pixel = grabImage(item).pixel(x, y);
        return 1 - (pixel.r + pixel.g + pixel.b) / 3;
    }

    // A soft, tight, faint shadow: just past its edge the desktop is a little
    // darker, and a few pixels further it is untouched.
    function test_aSoftShadowSurroundsTheCapsule() {
        const built = createTemporaryObject(area, this);

        const under = shadeAt(built, 150, 61);
        verify(under > 0.02, "shaded just below: " + under);
        verify(under < 0.35, "faint: " + under);
        verify(shadeAt(built, 150, 18) > 0, "shaded just above");
        verify(shadeAt(built, 48, 40) > 0, "shaded just past its end");
        compare(shadeAt(built, 150, 90), 0, "tight");
    }

    // The shadow takes the capsule's shape: past a pill's round end the
    // corner of its box stays clear, while round a popup, as a rounded
    // rectangle, it is shaded there; and it follows the capsule as it grows.
    function test_theShadowFollowsTheCapsulesShape() {
        const built = createTemporaryObject(area, this);

        compare(shadeAt(built, 51, 19), 0, "clear past a pill's round end");
        built.surface.place = { x: 50, y: 20, width: 200, height: 40, radius: 4 };
        verify(shadeAt(built, 51, 19) > 0, "shaded at a rounded rectangle's corner");
        built.surface.place = { x: 50, y: 20, width: 200, height: 60, radius: 4 };
        verify(shadeAt(built, 150, 81) > 0.02, "shaded below the grown capsule");
    }

    // With no row there is no capsule, and no shadow either.
    Component {
        id: seeThrough

        Rectangle {
            property alias surface: surface

            width: 300
            height: 100
            color: "#ffffff"

            CapsuleSurface {
                id: surface

                place: ({ x: 50, y: 20, width: 200, height: 40, radius: 20 })
                fillColor: Qt.rgba(0, 0, 0, 0.5)
                appearance: ({ barPosition: "top", motion: Motion.motion(true) })
            }
        }
    }

    // Expanded it is more solid: its fill 15 points more opaque than the
    // profile's opacity, over the white desktop here; collapsing returns it.
    function test_expandedTheCapsuleIsMoreOpaque() {
        const built = createTemporaryObject(seeThrough, this);
        fuzzyCompare(shadeAt(built, 150, 40), 0.5, 0.01);

        built.surface.expanded = true;
        fuzzyCompare(shadeAt(built, 150, 40), 0.65, 0.01);

        built.surface.expanded = false;
        fuzzyCompare(shadeAt(built, 150, 40), 0.5, 0.01);
    }

    // Its shadow is a little larger expanded: it reaches a couple of pixels
    // further, and is darker just past its edge; collapsing returns it.
    function test_expandedTheShadowIsLarger() {
        const built = createTemporaryObject(area, this);
        const restingEdge = shadeAt(built, 150, 60);
        compare(shadeAt(built, 150, 65), 0, "at rest it ends within four pixels");

        built.surface.expanded = true;
        verify(shadeAt(built, 150, 65) > 0, "reaches further expanded");
        verify(shadeAt(built, 150, 60) > restingEdge, "darker at its edge expanded");
        compare(shadeAt(built, 150, 90), 0, "still tight");

        built.surface.expanded = false;
        compare(shadeAt(built, 150, 65), 0, "back at rest");
        compare(shadeAt(built, 150, 60), restingEdge, "back at rest");
    }

    // Without reduce motion it gets more solid on the capsule's spring,
    // settling in about 350 ms, and back again collapsing.
    function test_itGetsMoreSolidOnTheCapsulesSpring() {
        const built = createTemporaryObject(seeThrough, this);
        built.surface.appearance = { barPosition: "top", motion: Motion.motion(false) };

        built.surface.expanded = true;
        verify(shadeAt(built, 150, 40) < 0.64, "moves rather than jumps");
        tryVerify(() => Math.abs(shadeAt(built, 150, 40) - 0.65) < 0.01, 600, "settles expanded");

        built.surface.expanded = false;
        verify(shadeAt(built, 150, 40) > 0.51, "moves back rather than jumps");
        tryVerify(() => Math.abs(shadeAt(built, 150, 40) - 0.5) < 0.01, 600, "settles at rest");
    }

    function test_aCapsuleWithNoSizeCastsNoShadow() {
        const built = createTemporaryObject(area, this);

        built.surface.place = { x: 150, y: 40, width: 0, height: 0, radius: 0 };
        compare(shadeAt(built, 150, 40), 0);
    }

    Component {
        id: springy

        CapsuleSurface {
            // The widest and narrowest it has been, and the smallest corner
            // radius, since `reset`.
            property real widest: 0
            property real narrowest: 0
            property real roundest: 0
            property real squarest: 0

            function reset() {
                widest = narrowest = width;
                roundest = squarest = radius;
            }

            place: ({ x: 50, y: 0, width: 200, height: 40, radius: 20 })
            fillColor: "#ff0000"
            appearance: ({ barPosition: "top", motion: Motion.motion(false) })
            onWidthChanged: {
                widest = Math.max(widest, width);
                narrowest = Math.min(narrowest, width);
            }
            onRadiusChanged: {
                roundest = Math.max(roundest, radius);
                squarest = Math.min(squarest, radius);
            }
        }
    }

    // Growing, it springs past where it ends and settles there in about
    // 350 ms.
    function test_growingOvershootsThenSettles() {
        const surface = createTemporaryObject(springy, this);
        surface.reset();

        surface.place = { x: 0, y: 0, width: 300, height: 200, radius: 20 };

        tryVerify(() => surface.widest > 300, 400, "overshoots");
        tryCompare(surface, "width", 300, 600);
        compare(surface.height, 200);
        compare(surface.x, 0);
    }

    // Shrinking, it eases to where it ends without bouncing past it.
    function test_shrinkingSettlesWithoutBounce() {
        const surface = createTemporaryObject(springy, this);
        surface.reset();

        surface.place = { x: 100, y: 0, width: 100, height: 40, radius: 20 };

        tryCompare(surface, "width", 100, 600);
        compare(surface.narrowest, 100);
        verify(surface.widest <= 200);
    }

    // Round a popup its corners morph from a pill's down to a rounded
    // rectangle's, and back.
    function test_theCornersMorphBetweenPillAndRoundedRectangle() {
        const surface = createTemporaryObject(springy, this);
        surface.reset();

        surface.place = { x: 0, y: 0, width: 300, height: 200, radius: 12 };
        verify(surface.radius > 12, "morphs rather than jumps");
        tryCompare(surface, "radius", 12, 600);
        verify(surface.roundest <= 20 + 0.001);

        surface.place = { x: 50, y: 0, width: 200, height: 40, radius: 20 };
        tryCompare(surface, "radius", 20, 600);
    }

    // With reduce motion it is where it ends at once.
    function test_reduceMotionMovesAtOnce() {
        const surface = createTemporaryObject(springy, this, {
            appearance: { barPosition: "top", motion: Motion.motion(true) }
        });

        surface.place = { x: 0, y: 0, width: 300, height: 200, radius: 12 };

        compare([surface.x, surface.y, surface.width, surface.height, surface.radius], [0, 0, 300, 200, 12]);
    }

    // While a popup inside resizes itself in its own animation, the capsule
    // follows its depth frame by frame.
    function test_followingAPopupTracksItsDepthAtOnce() {
        const surface = createTemporaryObject(springy, this, { following: true });

        surface.place = { x: 50, y: 0, width: 200, height: 260, radius: 20 };

        compare(surface.height, 260);
    }
}
