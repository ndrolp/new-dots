import QtQuick
import QtTest
import "../components/bar"
import "../config/Motion.js" as Motion

// The capsule is drawn in the profile's background colour and opacity, with
// the bar border around it when that setting is on.
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
                borderColor: "#0000ff"
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

    function test_theBarBorderRunsAroundTheCapsuleWhenOn() {
        const built = createTemporaryObject(area, this);

        compare(colorAt(built, 150, 20), { r: 1, g: 0, b: 0 });
        built.surface.border = true;
        compare(colorAt(built, 150, 20), { r: 0, g: 0, b: 1 });
        compare(colorAt(built, 150, 59), { r: 0, g: 0, b: 1 });
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
