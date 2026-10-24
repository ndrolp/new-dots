import QtQuick
import QtTest
import "../components/panels" as Panels

// The surface every popup draws on: a flat card with a hairline border, its
// contents inset by the padding, opening with a short fade and slide down.
TestCase {
    name: "PopupSurface"
    width: 400
    height: 400
    when: windowShown

    Component {
        id: surfaceWithBox

        Panels.PopupSurface {
            property alias box: box

            width: 200

            Rectangle {
                id: box

                width: parent.width
                height: 50
            }
        }
    }

    function makeSurface(properties) {
        return createTemporaryObject(surfaceWithBox, this, properties || {});
    }

    function test_contentsSitInsideThePadding() {
        const surface = makeSurface({ open: true, padding: 12 });

        tryCompare(surface, "reveal", 1);
        const corner = surface.box.mapToItem(surface, 0, 0);
        compare(corner.x, 12);
        compare(corner.y, 12);
        compare(surface.box.width, 176);
    }

    function test_theSurfaceIsFlatWithAHairlineBorder() {
        const surface = makeSurface({ open: true });

        compare(surface.border.width, 1);
        verify(!surface.layer.enabled);
    }

    function test_aClosedSurfaceIsTransparentAndRaised() {
        const surface = makeSurface({ open: false });

        compare(surface.opacity, 0);
        verify(surface.mapToItem(surface.parent, 0, 0).y < 0);
    }

    function test_openingFadesInAndSlidesDownToRestInAboutAnEighthOfASecond() {
        const surface = makeSurface({ open: false });

        surface.open = true;
        verify(surface.reveal < 1);
        tryCompare(surface, "opacity", 1, 300);
        compare(surface.mapToItem(surface.parent, 0, 0).y, 0);
    }

    function test_theSurfaceIsAsTallAsItsContentsPlusThePadding() {
        const surface = makeSurface({ padding: 12 });

        compare(surface.implicitHeight, 74);
        surface.box.height = 100;
        compare(surface.implicitHeight, 124);
    }
}
