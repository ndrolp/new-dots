import QtQuick
import QtTest
import "../components/bar"

// A zone of the docked bar hangs from the bar's screen edge with the outline of
// an attached popup, except that a side on the screen's edge stays straight.
TestCase {
    name: "DockedSurface"
    width: 500
    height: 500
    visible: true
    when: windowShown

    Component {
        id: surface

        DockedSurface {
            thickness: 30
            fillColor: "#ff0000"
            spanLeft: 100
            spanRight: 300
            motion: ({ medium: 0, easing: 0 })
        }
    }

    // Whether the zone has painted the given point, in the zone: the window
    // behind it is white.
    function painted(item, x, y) {
        return grabImage(item).pixel(x, y).g < 0.5;
    }

    function test_aZoneInTheMiddleLeavesRoomForItsJoinsOnBothSides() {
        const item = createTemporaryObject(surface, this);

        compare(item.path.segments[2], { x: 194, y: 22 });
        compare(item.path.segments[6], { x: 6, y: 6 });
    }

    function test_aZoneOnTheLeftOfTheScreenKeepsItsLeftEdgeStraight() {
        const item = createTemporaryObject(surface, this, { keepLeftEdge: true });

        compare(item.path.segments[2], { x: 194, y: 22 });
        compare(item.path.segments[4], { x: 0, y: 30 });
    }

    function test_aZoneOnTheRightOfTheScreenKeepsItsRightEdgeStraight() {
        const item = createTemporaryObject(surface, this, { keepRightEdge: true });

        compare(item.path.segments[1], { x: 200, y: 30 });
        compare(item.path.segments[4], { x: 6, y: 6 });
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

    function test_aBottomZoneGrowsForAPopupOpeningUpwards() {
        const item = createTemporaryObject(surface, this,
            { barPosition: "bottom", popup: { left: 50, right: 350 } });

        tryCompare(item, "x", 36);
        tryCompare(item, "width", 328);
        compare(item.y, 0);
        compare(item.height, 30);
    }

    function test_aZoneRunsAlongTheBarOnEveryEdge_data() {
        return [
            { tag: "top", box: { x: 100, y: 0, width: 200, height: 30 } },
            { tag: "bottom", box: { x: 100, y: 0, width: 200, height: 30 } },
            { tag: "left", box: { x: 0, y: 100, width: 30, height: 200 } },
            { tag: "right", box: { x: 0, y: 100, width: 30, height: 200 } }
        ];
    }

    function test_aZoneRunsAlongTheBarOnEveryEdge(data) {
        const item = createTemporaryObject(surface, this, { barPosition: data.tag });

        compare({ x: item.x, y: item.y, width: item.width, height: item.height }, data.box);
    }

    function test_aSideZoneGrowsDownTheBar() {
        const item = createTemporaryObject(surface, this,
            { barPosition: "right", keepRightEdge: true, popup: { left: 50, right: 350 } });

        tryCompare(item, "y", 36);
        tryCompare(item, "height", 264);
        compare(item.x, 0);
        compare(item.width, 30);
    }

    function test_itsBottomCornersAreAsRoundAsAPopups() {
        const item = createTemporaryObject(surface, this);

        compare(item.path.segments[3], { x: 186, y: 30, controlX: 194, controlY: 30 });
    }

    function test_aZoneHangsFromTheBarsEdge_data() {
        return [
            { tag: "top", atTheBar: [5, 1], awayFromIt: [5, 28], theMiddle: [100, 15] },
            { tag: "bottom", atTheBar: [5, 28], awayFromIt: [5, 1], theMiddle: [100, 15] },
            { tag: "left", atTheBar: [1, 5], awayFromIt: [28, 5], theMiddle: [15, 100] },
            { tag: "right", atTheBar: [28, 5], awayFromIt: [1, 5], theMiddle: [15, 100] }
        ];
    }

    function test_aZoneHangsFromTheBarsEdge(data) {
        const item = createTemporaryObject(surface, this, { barPosition: data.tag });

        tryVerify(() => painted(item, data.theMiddle[0], data.theMiddle[1]));
        verify(painted(item, data.atTheBar[0], data.atTheBar[1]), "its join meets the bar");
        verify(!painted(item, data.awayFromIt[0], data.awayFromIt[1]), "its corner is round");
    }

    function test_aBottomZoneIsStraightWhereItMeetsTheScreensSide_data() {
        return [
            { tag: "left", keep: { keepLeftEdge: true }, straight: [1, 1], round: [193, 1] },
            { tag: "right", keep: { keepRightEdge: true }, straight: [198, 1], round: [7, 1] }
        ];
    }

    function test_aBottomZoneIsStraightWhereItMeetsTheScreensSide(data) {
        const item = createTemporaryObject(surface, this,
            Object.assign({ barPosition: "bottom" }, data.keep));

        tryVerify(() => painted(item, 100, 15));
        verify(painted(item, data.straight[0], data.straight[1]), "the screen's side stays straight");
        verify(!painted(item, data.round[0], data.round[1]), "the inner side is round");
    }

    function test_movingTheBarRepaintsTheZone() {
        const item = createTemporaryObject(surface, this);

        tryVerify(() => painted(item, 5, 1));
        item.barPosition = "bottom";
        tryVerify(() => painted(item, 5, 28));
        tryVerify(() => !painted(item, 5, 1));
    }
}
