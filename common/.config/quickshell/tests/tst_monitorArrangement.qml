import QtQuick
import QtTest
import "../services/MonitorArrangement.js" as MonitorArrangement

// Where monitors sit on the arrange canvas: edge to edge, with no gaps.
TestCase {
    name: "MonitorArrangement"

    function rect(id, x, y, width, height) {
        return { id: id, x: x, y: y, width: width, height: height };
    }

    function at(rects, id) {
        const found = rects.filter(r => r.id === id)[0];
        return [found.x, found.y];
    }

    function overlapping(rects) {
        return rects.some((a, i) => rects.some((b, j) => j > i && MonitorArrangement.overlap(a, b)));
    }

    function connected(rects) {
        return MonitorArrangement.reachable(rects, rects[0]).length === rects.length;
    }

    readonly property var pair: [rect("a", 0, 0, 1800, 1125), rect("b", 1800, 0, 2560, 1440)]

    function test_droppingNearAnEdgeSnapsToIt() {
        const placed = MonitorArrangement.snapped(pair, "b", 1900, 30);
        compare(at(placed, "a"), [0, 0]);
        compare(at(placed, "b"), [1800, 0]);
    }

    function test_aMonitorDroppedFarAwayStillEndsUpTouching() {
        const placed = MonitorArrangement.snapped(pair, "b", 6000, 0);
        compare(at(placed, "b"), [1800, 0]);
    }

    function test_droppingAboveMovesItAboveAndTheCornerStaysAtTheOrigin() {
        const placed = MonitorArrangement.snapped(pair, "b", 0, -1500);
        compare(at(placed, "b"), [0, 0]);
        compare(at(placed, "a"), [0, 1440]);
    }

    function test_droppingOnTopOfAnotherPutsItBesideIt() {
        const placed = MonitorArrangement.snapped(pair, "b", 100, 100);
        compare(overlapping(placed), false);
        compare(connected(placed), true);
    }

    function test_aMonitorCanSitPartWayDownItsNeighbour() {
        const placed = MonitorArrangement.snapped(pair, "b", 1800, 300);
        compare(at(placed, "a"), [0, 0]);
        compare(at(placed, "b"), [1800, 300]);
    }

    function test_nearTheBottomEdgesTheyLineUp() {
        const placed = MonitorArrangement.snapped(pair, "b", 1800, -300);
        // Bottoms 1125 and 1140 apart by 15: b lines up with a's bottom, then the corner moves to 0.
        compare(at(placed, "b"), [1800, 0]);
        compare(at(placed, "a"), [0, 315]);
    }

    function test_movingTheMiddleMonitorAwayClosesTheGapItLeft() {
        const row = [rect("a", 0, 0, 1000, 800), rect("b", 1000, 0, 1000, 800), rect("c", 2000, 0, 1000, 800)];
        const placed = MonitorArrangement.snapped(row, "b", 500, 800);
        compare(connected(placed), true);
        compare(overlapping(placed), false);
        compare(at(placed, "a"), [0, 0]);
        compare(at(placed, "c"), [1000, 0]);
    }

    function test_aMonitorThatGrewPushesItsNeighbourAlong() {
        const grown = [rect("a", 0, 0, 2000, 1125), rect("b", 1800, 0, 2560, 1440)];
        const placed = MonitorArrangement.snapped(grown, "a", 0, 0);
        compare(at(placed, "a"), [0, 0]);
        compare(at(placed, "b"), [2000, 0]);
    }

    function test_aMonitorThatShrankLeavesNoGap() {
        const shrunk = [rect("a", 0, 0, 1600, 1000), rect("b", 1800, 0, 2560, 1440)];
        const placed = MonitorArrangement.snapped(shrunk, "a", 0, 0);
        compare(at(placed, "a"), [0, 0]);
        compare(at(placed, "b"), [1600, 0]);
    }

    function test_turningOffTheMiddleMonitorClosesTheGap() {
        const left = [rect("a", 0, 0, 1000, 800), rect("c", 2000, 0, 1000, 800)];
        const placed = MonitorArrangement.closed(left);
        compare(at(placed, "a"), [0, 0]);
        compare(at(placed, "c"), [1000, 0]);
    }

    function test_oneMonitorSitsAtTheOrigin() {
        const placed = MonitorArrangement.snapped([rect("a", 200, 300, 1800, 1125)], "a", 900, 900);
        compare(at(placed, "a"), [0, 0]);
    }

    function test_theSlotAtTheEndIsBesideEverything() {
        compare(MonitorArrangement.nextSlot(pair), { x: 4360, y: 0 });
        compare(MonitorArrangement.nextSlot([]), { x: 0, y: 0 });
    }
}
