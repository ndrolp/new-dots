import QtQuick
import QtTest
import "../components/bar"

// A zone of the docked bar has the outline of an attached popup, except that a
// side on the screen's edge stays straight.
TestCase {
    name: "DockedSurface"

    Component {
        id: surface

        DockedSurface {
            height: 30
            spanLeft: 100
            spanRight: 300
            motion: ({ medium: 0, easing: 0 })
        }
    }

    function test_aZoneInTheMiddleLeavesRoomForItsJoinsOnBothSides() {
        const item = createTemporaryObject(surface, this);

        compare(item.edgeLeft, 6);
        compare(item.edgeRight, 194);
    }

    function test_aZoneOnTheLeftOfTheScreenKeepsItsLeftEdgeStraight() {
        const item = createTemporaryObject(surface, this, { keepLeftEdge: true });

        compare(item.edgeLeft, 0);
        compare(item.edgeRight, 194);
    }

    function test_aZoneOnTheRightOfTheScreenKeepsItsRightEdgeStraight() {
        const item = createTemporaryObject(surface, this, { keepRightEdge: true });

        compare(item.edgeLeft, 6);
        compare(item.edgeRight, 200);
    }

    function test_aZoneGrowsPastAWiderPopupOnBothSides() {
        const item = createTemporaryObject(surface, this, { popup: { left: 50, right: 350 } });

        tryCompare(item, "x", 36);
        tryCompare(item, "width", 328);
    }

    function test_aZoneStaysPutForAPopupThatFitsUnderIt() {
        const item = createTemporaryObject(surface, this, { popup: { left: 130, right: 270 } });

        compare(item.x, 100);
        compare(item.width, 200);
    }

    function test_aZoneReturnsToItsPlaceWhenThePopupCloses() {
        const item = createTemporaryObject(surface, this, { popup: { left: 50, right: 350 } });

        item.popup = null;
        tryCompare(item, "x", 100);
        tryCompare(item, "width", 200);
    }

    function test_theSideOnTheScreensEdgeNeverMoves() {
        const item = createTemporaryObject(surface, this,
            { keepRightEdge: true, popup: { left: 50, right: 350 } });

        tryCompare(item, "x", 36);
        tryCompare(item, "width", 264);
    }

    function test_itsBottomCornersAreAsRoundAsAPopups() {
        const item = createTemporaryObject(surface, this);

        compare(item.corners, { join: 6, bottom: 8 });
    }
}
