import QtQuick
import QtTest
import "../components/bar"
import "../components/BarPosition.js" as BarPosition
import "../components/panels/PopupOutline.js" as PopupOutline
import "../components/panels/PopupPlacement.js" as PopupPlacement

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

    function test_aSideZoneIsStraightWhereItMeetsTheEndOfTheScreen_data() {
        return [
            { tag: "left bar, top end", barPosition: "left", keep: { keepLeftEdge: true },
                straight: [[1, 1], [28, 1]], round: [[1, 198], [28, 198]] },
            { tag: "left bar, bottom end", barPosition: "left", keep: { keepRightEdge: true },
                straight: [[1, 198], [28, 198]], round: [[1, 1], [28, 1]] },
            { tag: "right bar, top end", barPosition: "right", keep: { keepLeftEdge: true },
                straight: [[28, 1], [1, 1]], round: [[28, 198], [1, 198]] },
            { tag: "right bar, bottom end", barPosition: "right", keep: { keepRightEdge: true },
                straight: [[28, 198], [1, 198]], round: [[28, 1], [1, 1]] }
        ];
    }

    function test_aSideZoneIsStraightWhereItMeetsTheEndOfTheScreen(data) {
        const item = createTemporaryObject(surface, this,
            Object.assign({ barPosition: data.barPosition }, data.keep));

        tryVerify(() => painted(item, 15, 100));
        for (const point of data.straight)
            verify(painted(item, point[0], point[1]), "the end of the screen stays straight");
        for (const point of data.round)
            verify(!painted(item, point[0], point[1]), "the other end curves");
    }

    function test_aSideZoneWidensBesideThePopupThatOpensFromIt_data() {
        return [
            { tag: "left", inner: 28 },
            { tag: "right", inner: 1 }
        ];
    }

    function test_aSideZoneWidensBesideThePopupThatOpensFromIt(data) {
        const item = createTemporaryObject(surface, this,
            { barPosition: data.tag, popup: { left: 50, right: 350 } });

        tryCompare(item, "y", 36);
        tryCompare(item, "height", 328);
        tryVerify(() => painted(item, data.inner, 15));
        verify(painted(item, data.inner, 312), "its inner side reaches past the popup's far join");
    }

    function test_aZoneGrowsSlowlyForAPopupThatOpens() {
        const item = createTemporaryObject(surface, this, {
            motion: { medium: 100000, easing: 0 }
        });

        item.popup = { left: 50, right: 200, resizing: false };
        verify(item.growLeft < 1, "the growth animates");
    }

    // A popup resizing along a side bar (the control center changing stage): its
    // own animation is the zone's, or the zone would lag behind it.
    function test_aZoneKeepsUpWithAResizingPopup() {
        const item = createTemporaryObject(surface, this, {
            motion: { medium: 100000, easing: 0 },
            barPosition: "left"
        });

        item.popup = { left: 150, right: 250, resizing: true };
        item.popup = { left: 50, right: 200, resizing: true };
        verify(item.growth.left > 0);
        compare(item.growLeft, item.growth.left);
        item.popup = { left: 40, right: 200, resizing: true };
        compare(item.growLeft, item.growth.left);
    }

    // An attached popup in a bar window 30 thick and 800 long, opened by an
    // element 40 long at 300: 212 long and 320 deep, as its window is on every
    // Bar position. Returns where its joins start and end on the bar's inner
    // side, in the bar window.
    function attachedJoins(barPosition) {
        const sideBar = BarPosition.sideBar(barPosition);
        const windowWidth = sideBar ? 320 : 212;
        const windowHeight = sideBar ? 212 : 320;
        const room = PopupPlacement.room({ barPosition: barPosition, attached: true, inset: 12, joinRadius: 6 });
        const placed = PopupPlacement.position({
            barPosition: barPosition,
            popupWidth: windowWidth,
            popupHeight: windowHeight,
            window: { width: sideBar ? 30 : 800, height: sideBar ? 800 : 30 },
            barHeight: 30,
            padding: 10,
            radius: 8,
            spacing: 5,
            attached: true,
            trigger: { start: 300, length: 40 },
            edge: "right",
            content: null
        });
        const surfaceWidth = windowWidth - room.left - room.right;
        const surfaceHeight = windowHeight - room.top - room.bottom;
        const outline = PopupOutline.attachedPath({
            barPosition: barPosition,
            width: surfaceWidth,
            height: surfaceHeight,
            unfolded: sideBar ? surfaceWidth : surfaceHeight,
            radius: 8,
            joinRadius: 6
        });
        const left = placed.x + room.left + outline.x;
        const top = placed.y + room.top + outline.y;

        return {
            span: { left: placed.start, right: placed.end },
            start: { x: left + outline.start.x, y: top + outline.start.y },
            end: { x: left + outline.segments[0].x, y: top + outline.segments[0].y }
        };
    }

    function test_anAttachedPopupsJoinsMeetTheZoneItHangsFrom_data() {
        return [
            { tag: "top", start: { x: 214, y: 30 }, end: { x: 426, y: 30 } },
            { tag: "bottom", start: { x: 214, y: 0 }, end: { x: 426, y: 0 } },
            { tag: "left", start: { x: 30, y: 214 }, end: { x: 30, y: 426 } },
            { tag: "right", start: { x: 0, y: 214 }, end: { x: 0, y: 426 } }
        ];
    }

    function test_anAttachedPopupsJoinsMeetTheZoneItHangsFrom(data) {
        const joins = attachedJoins(data.tag);
        const item = createTemporaryObject(surface, this,
            { barPosition: data.tag, spanLeft: 300, spanRight: 340, popup: joins.span });

        tryCompare(item, "zoneLength", 240);

        // The straight stretch of the zone's inner side, between its corners.
        const flatEnd = item.path.segments[3];
        const flatStart = item.path.segments[4];

        compare(joins.start, data.start);
        compare(joins.end, data.end);
        compare({ x: item.x + flatStart.x, y: item.y + flatStart.y }, data.start);
        compare({ x: item.x + flatEnd.x, y: item.y + flatEnd.y }, data.end);
    }

    function test_movingTheBarRepaintsTheZone() {
        const item = createTemporaryObject(surface, this);

        tryVerify(() => painted(item, 5, 1));
        item.barPosition = "bottom";
        tryVerify(() => painted(item, 5, 28));
        tryVerify(() => !painted(item, 5, 1));
    }

    function test_movingTheBarToTheSideRepaintsTheZone() {
        const item = createTemporaryObject(surface, this);

        tryVerify(() => painted(item, 5, 1));
        item.barPosition = "right";
        tryVerify(() => item.height === 200 && painted(item, 15, 100));
        verify(painted(item, 28, 5), "its join meets the bar");
        verify(!painted(item, 1, 5), "its corner is round");
    }
}
