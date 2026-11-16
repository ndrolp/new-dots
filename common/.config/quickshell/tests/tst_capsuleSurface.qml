import QtQuick
import QtTest
import "../components/bar"

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
                appearance: ({ barPosition: "top", motion: { medium: 0, long: 0, easing: 0 } })
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
}
