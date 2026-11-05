import QtQuick
import QtTest
import "../components/BarPosition.js" as BarPosition

// Things laid out from the bar are measured along it and away from it; the Bar
// position turns that into the screen's x and y.
TestCase {
    name: "BarPosition"

    function test_onlyLeftAndRightAreSideBars() {
        verify(!BarPosition.sideBar("top"));
        verify(!BarPosition.sideBar("bottom"));
        verify(BarPosition.sideBar("left"));
        verify(BarPosition.sideBar("right"));
    }

    function test_aPointIsLaidOnThePosition_data() {
        return [
            { tag: "top", point: { x: 10, y: 3 } },
            { tag: "bottom", point: { x: 10, y: 47 } },
            { tag: "left", point: { x: 3, y: 10 } },
            { tag: "right", point: { x: 47, y: 10 } }
        ];
    }

    function test_aPointIsLaidOnThePosition(data) {
        compare(BarPosition.point(data.tag, 10, 3, 50), data.point);
    }

    function test_anAreaIsLaidOnThePosition_data() {
        return [
            { tag: "top", area: { x: 10, y: 3, width: 100, height: 20 } },
            { tag: "bottom", area: { x: 10, y: 27, width: 100, height: 20 } },
            { tag: "left", area: { x: 3, y: 10, width: 20, height: 100 } },
            { tag: "right", area: { x: 27, y: 10, width: 20, height: 100 } }
        ];
    }

    function test_anAreaIsLaidOnThePosition(data) {
        compare(BarPosition.area(data.tag, { along: 10, away: 3, length: 100, depth: 20 }, 50), data.area);
    }

    function test_roomIsLaidOnThePosition_data() {
        return [
            { tag: "top", room: { top: 1, right: 3, bottom: 2, left: 3 } },
            { tag: "bottom", room: { top: 2, right: 3, bottom: 1, left: 3 } },
            { tag: "left", room: { top: 3, right: 2, bottom: 3, left: 1 } },
            { tag: "right", room: { top: 3, right: 1, bottom: 3, left: 2 } }
        ];
    }

    function test_roomIsLaidOnThePosition(data) {
        compare(BarPosition.sides(data.tag, 1, 2, 3), data.room);
    }
}
