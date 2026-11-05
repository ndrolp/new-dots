import QtQuick
import QtTest
import "../components/panels" as Panels
import "../config" as Config
import "../config/Motion.js" as Motion

// The surface every popup draws on: a flat card with a hairline border, its
// contents inset by the padding, opening with a short fade and slide down.
// Attached to the bar it has no border and unfolds downward instead, its
// contents fading in after. The host may paint it in its own colors. It
// opens with the motion settings it is given, so reduce motion opens it at once.
// It takes input while open or opening, and none while it closes.
TestCase {
    name: "PopupSurface"
    width: 400
    height: 400
    when: windowShown
    // Shown, so that clicks reach the contents.
    visible: true

    Config.Theme {
        id: theme
    }

    Component {
        id: surfaceWithBox

        Panels.PopupSurface {
            property alias box: box

            width: 200
            motion: Motion.motion(false)

            Rectangle {
                id: box

                width: parent.width
                height: 50
            }
        }
    }

    // Contents to press, the way popups have them, on a surface that closes
    // slowly enough for a test to act while the close animation runs.
    Component {
        id: surfaceWithInputs

        Panels.PopupSurface {
            id: inputs

            property alias area: area
            property alias field: field
            property int tapped: 0
            property int pressed: 0

            width: 200
            motion: ({ short: 60000, medium: 60000, easing: 6 })

            Rectangle {
                width: parent.width
                height: 50

                TapHandler {
                    onTapped: inputs.tapped++
                }
            }

            MouseArea {
                id: area

                width: parent.width
                height: 50
                y: 50
                onPressed: inputs.pressed++
            }

            Panels.PopupTextField {
                id: field

                width: parent.width
                height: 32
                y: 100
                appearance: ({ radius: 6, textSize: 13 })
            }
        }
    }

    function makeSurface(properties) {
        return createTemporaryObject(surfaceWithBox, this, properties || {});
    }

    // A surface with inputs, already fully open.
    function makeOpenInputs(properties) {
        const surface = createTemporaryObject(surfaceWithInputs, this, properties || {});
        const slow = surface.motion;
        surface.motion = Motion.motion(true);
        surface.open = true;
        compare(surface.reveal, 1);
        surface.motion = slow;
        return surface;
    }

    // How opaque an item is drawn, with the opacity of every item above it up
    // to and including the surface.
    function drawnOpacity(item, surface) {
        let opacity = 1;
        for (let current = item; current && current !== surface.parent; current = current.parent)
            opacity *= current.opacity;
        return opacity;
    }

    // Moves the reveal to a point of the opening animation and waits there.
    function revealTo(surface, reveal) {
        surface.reveal = reveal;
        tryCompare(surface, "reveal", reveal, 1000);
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

    function test_withReduceMotionASurfaceOpensAndClosesAtOnce() {
        const surface = makeSurface({ open: false, motion: Motion.motion(true) });

        surface.open = true;
        compare(surface.reveal, 1);
        compare(surface.opacity, 1);
        surface.open = false;
        compare(surface.reveal, 0);
    }

    function test_withReduceMotionAnAttachedSurfaceUnfoldsAtOnce() {
        const surface = makeSurface({ attached: true, open: false, motion: Motion.motion(true) });

        surface.open = true;
        compare(surface.unfoldedHeight, surface.implicitHeight);
    }

    function test_theSurfaceIsAsTallAsItsContentsPlusThePadding() {
        const surface = makeSurface({ padding: 12 });

        compare(surface.implicitHeight, 74);
        surface.box.height = 100;
        compare(surface.implicitHeight, 124);
    }

    function test_theHostCanPaintTheSurfaceInItsOwnColors() {
        const surface = makeSurface({ fillColor: "#102030", borderColor: "#405060" });

        verify(Qt.colorEqual(surface.color, "#102030"));
        verify(Qt.colorEqual(surface.border.color, "#405060"));
    }

    function test_anAttachedSurfaceIsPaintedInTheBarsColorAndOpacity() {
        const surface = makeSurface({ attached: true, barOpacity: 70, fillColor: "#102030" });

        verify(Qt.colorEqual(surface.attachedColor, Qt.rgba(theme.background.r, theme.background.g,
            theme.background.b, 0.7)));
        surface.barOpacity = 100;
        verify(Qt.colorEqual(surface.attachedColor, theme.background));
    }

    function test_anAttachedSurfaceIsOpaqueUnlessTheBarSaysOtherwise() {
        const surface = makeSurface({ attached: true });

        verify(Qt.colorEqual(surface.attachedColor, theme.background));
    }

    function test_anAttachedSurfaceHasNoBorderAndDoesNotFadeOrSlide() {
        const surface = makeSurface({ attached: true, open: false });

        revealTo(surface, 0.5);
        compare(surface.border.width, 0);
        compare(surface.opacity, 1);
        compare(surface.mapToItem(surface.parent, 0, 0).y, 0);
    }

    function test_anAttachedSurfaceUnfoldsDownwardFromItsTopEdge() {
        const surface = makeSurface({ attached: true, open: false, padding: 12 });

        compare(surface.unfoldedHeight, 0);
        revealTo(surface, 0.5);
        compare(surface.unfoldedHeight, 37);
        revealTo(surface, 1);
        compare(surface.unfoldedHeight, 74);
    }

    function test_anAttachedSurfacesContentsFadeInAfterItStartsUnfolding() {
        const surface = makeSurface({ attached: true, open: false });

        revealTo(surface, 0.3);
        compare(drawnOpacity(surface.box, surface), 0);
        revealTo(surface, 0.75);
        const halfway = drawnOpacity(surface.box, surface);
        verify(halfway > 0 && halfway < 1);
        revealTo(surface, 1);
        compare(drawnOpacity(surface.box, surface), 1);
    }

    function test_anOpenSurfaceTakesClicksOnItsContents() {
        const surface = makeOpenInputs();

        mouseClick(surface, surface.width / 2, 30);
        compare(surface.tapped, 1);
    }

    function test_aClosingSurfaceIgnoresClicksOnItsContents() {
        const surface = makeOpenInputs();

        surface.open = false;
        verify(surface.reveal > 0);
        mouseClick(surface, surface.width / 2, 30);
        compare(surface.tapped, 0);
    }

    function test_anAttachedClosingSurfaceIgnoresClicksOnItsContents() {
        const surface = makeOpenInputs({ attached: true });

        surface.open = false;
        verify(surface.reveal > 0);
        mouseClick(surface, surface.width / 2, 30);
        compare(surface.tapped, 0);
    }

    function test_aClosingSurfaceIgnoresMouseAreas() {
        const surface = makeOpenInputs();

        mouseClick(surface.area);
        compare(surface.pressed, 1);
        surface.open = false;
        mouseClick(surface.area);
        compare(surface.pressed, 1);
    }

    function test_aClosingSurfaceIgnoresTyping() {
        const surface = makeOpenInputs();

        surface.field.forceActiveFocus();
        keyClick("a");
        compare(surface.field.text, "a");
        surface.open = false;
        verify(surface.reveal > 0);
        keyClick("b");
        compare(surface.field.text, "a");
    }

    function test_reopeningLetsAFocusedFieldTakeTypingAgain() {
        const surface = makeOpenInputs();

        surface.field.forceActiveFocus();
        surface.open = false;
        surface.open = true;
        keyClick("a");
        compare(surface.field.text, "a");
    }

    function test_reopeningDuringTheCloseTakesClicksAgain() {
        const surface = makeOpenInputs();

        surface.open = false;
        verify(surface.reveal > 0);
        surface.open = true;
        mouseClick(surface, surface.width / 2, 30);
        compare(surface.tapped, 1);
    }

    function test_reopeningAfterClosingTakesClicksAgain() {
        const surface = makeOpenInputs({ motion: Motion.motion(true) });

        surface.open = false;
        compare(surface.reveal, 0);
        surface.open = true;
        mouseClick(surface, surface.width / 2, 30);
        compare(surface.tapped, 1);
    }

    function test_anOpeningSurfaceAlreadyTakesClicks() {
        const surface = createTemporaryObject(surfaceWithInputs, this, { open: false });

        surface.open = true;
        verify(surface.reveal < 1);
        mouseClick(surface, surface.width / 2, 30);
        compare(surface.tapped, 1);
    }

    function test_aFloatingSurfaceDrawsItsContentsAsItFades() {
        const surface = makeSurface({ open: false });

        revealTo(surface, 0.3);
        compare(drawnOpacity(surface.box, surface), 0.3);
    }
}
