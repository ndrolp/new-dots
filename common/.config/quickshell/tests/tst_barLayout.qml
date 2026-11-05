import QtQuick
import QtTest
import "../components/bar/BarLayout.js" as BarLayout

// Bar elements run along the bar: left to right on a top or bottom bar, top
// to bottom on a side bar, with the same spacing and groups either way.
TestCase {
    name: "BarLayout"

    function bar(barPosition) {
        return { barPosition: barPosition, width: 1000, height: 40, spacing: 4, groupPadding: 4, endPadding: 0 };
    }

    function sideBar(barPosition) {
        return { barPosition: barPosition, width: 40, height: 800, spacing: 4, groupPadding: 4, endPadding: 0 };
    }

    readonly property var lengths: ({ arch: 30, clock: 50, tray: 20 })

    function test_elementsRunAlongTheBar_data() {
        return ["top", "bottom", "left", "right"].map(position => ({ tag: position, position: position }));
    }

    function test_elementsRunAlongTheBar(data) {
        const zone = BarLayout.zone(bar(data.position), [["arch"], ["clock"]], element => lengths[element]);

        compare(zone.positions, {
            arch: { start: 0, grouped: false },
            clock: { start: 34, grouped: false }
        });
        compare(zone.length, 84);
        compare(zone.backgrounds, []);
    }

    function test_aGroupSharesOneBackgroundAlongTheBar() {
        const zone = BarLayout.zone(sideBar("left"), [["tray"], ["arch", "clock"]], element => lengths[element]);

        compare(zone.positions, {
            tray: { start: 0, grouped: false },
            arch: { start: 28, grouped: true },
            clock: { start: 62, grouped: true }
        });
        compare(zone.backgrounds, [{ start: 24, length: 92 }]);
        compare(zone.length, 116);
    }

    function test_anEmptyZoneTakesNoRoom() {
        compare(BarLayout.zone(bar("top"), [], element => 0), { positions: {}, backgrounds: [], length: 0 });
    }

    function test_anElementsLengthIsItsWidthOnATopOrBottomBar() {
        const item = { width: 60, height: 28 };

        compare(BarLayout.itemLength(bar("top"), item), 60);
        compare(BarLayout.itemLength(bar("bottom"), item), 60);
    }

    function test_anElementsLengthIsItsHeightOnASideBar() {
        const item = { width: 60, height: 28 };

        compare(BarLayout.itemLength(sideBar("left"), item), 28);
        compare(BarLayout.itemLength(sideBar("right"), item), 28);
    }

    function test_aBarWithoutAPositionLaysOutLikeATopBar() {
        const noPosition = bar(undefined);

        compare(BarLayout.itemLength(noPosition, { width: 60, height: 28 }), 60);
        compare(BarLayout.zoneStart(noPosition, "right", 100), 900);
    }

    function test_zonesSitAtTheEndsAndCentreOfATopBar() {
        compare(BarLayout.zoneStart(bar("top"), "left", 100), 0);
        compare(BarLayout.zoneStart(bar("top"), "center", 100), 450);
        compare(BarLayout.zoneStart(bar("top"), "right", 100), 900);
    }

    // Left is the top and right the bottom on both sides, never mirrored.
    function test_zonesSitAtTheTopCentreAndBottomOfASideBar_data() {
        return ["left", "right"].map(position => ({ tag: position, position: position }));
    }

    function test_zonesSitAtTheTopCentreAndBottomOfASideBar(data) {
        compare(BarLayout.zoneStart(sideBar(data.position), "left", 100), 0);
        compare(BarLayout.zoneStart(sideBar(data.position), "center", 100), 350);
        compare(BarLayout.zoneStart(sideBar(data.position), "right", 100), 700);
    }

    function test_theEndPaddingKeepsZonesOffTheBarsEnds() {
        const padded = Object.assign(sideBar("left"), { endPadding: 12 });

        compare(BarLayout.zoneStart(padded, "left", 100), 12);
        compare(BarLayout.zoneStart(padded, "center", 100), 350);
        compare(BarLayout.zoneStart(padded, "right", 100), 688);
    }

    function test_aCentredZoneLandsOnAWholePixel() {
        compare(BarLayout.zoneStart(bar("top"), "center", 101), 450);
    }

    function test_anElementSitsAtItsStartAndCentredAcrossATopOrBottomBar_data() {
        return ["top", "bottom"].map(position => ({ tag: position, position: position }));
    }

    function test_anElementSitsAtItsStartAndCentredAcrossATopOrBottomBar(data) {
        compare(BarLayout.place(bar(data.position), 120, { width: 60, height: 28 }), { x: 120, y: 6 });
    }

    function test_anElementSitsAtItsStartAndCentredAcrossASideBar_data() {
        return ["left", "right"].map(position => ({ tag: position, position: position }));
    }

    function test_anElementSitsAtItsStartAndCentredAcrossASideBar(data) {
        compare(BarLayout.place(sideBar(data.position), 120, { width: 28, height: 60 }), { x: 6, y: 120 });
    }

    Component {
        id: anchoredBar

        Item {
            property alias element: element

            anchors.fill: parent

            Item {
                id: element

                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }

    Item {
        id: host

        width: 1000
    }

    // Bar elements used to be centred with anchors, whose rounding a top bar
    // has to keep to the pixel.
    function test_centringAcrossTheBarRoundsLikeAnchors_data() {
        const sizes = [];
        for (const barSize of [30, 31, 34, 35, 30.5])
            for (const elementSize of [14, 15, 20, 21, 20.5, 21.5, 33])
                sizes.push({ tag: barSize + "/" + elementSize, barSize: barSize, elementSize: elementSize });
        return sizes;
    }

    function test_centringAcrossTheBarRoundsLikeAnchors(data) {
        host.height = data.barSize;
        const anchored = createTemporaryObject(anchoredBar, host);
        anchored.element.height = data.elementSize;

        const placed = BarLayout.place(Object.assign(bar("top"), { height: data.barSize }), 0,
            { width: 10, height: data.elementSize });

        compare(placed.y, anchored.element.y);
    }

    function test_aGroupBackgroundSpansTheThicknessOfATopOrBottomBar() {
        compare(BarLayout.groupBackground(bar("top"), 24, 92), { x: 24, y: 0, width: 92, height: 40 });
        compare(BarLayout.groupBackground(bar("bottom"), 24, 92), { x: 24, y: 0, width: 92, height: 40 });
    }

    function test_aGroupBackgroundSpansTheThicknessOfASideBar() {
        compare(BarLayout.groupBackground(sideBar("left"), 24, 92), { x: 0, y: 24, width: 40, height: 92 });
        compare(BarLayout.groupBackground(sideBar("right"), 24, 92), { x: 0, y: 24, width: 40, height: 92 });
    }

    function test_aPopupTriggerIsItsWholeElement() {
        compare(BarLayout.trigger({ x: 6, y: 120, width: 28, height: 60 }, null),
            { x: 6, y: 120, width: 28, height: 60 });
    }

    // The app menu's titles each open their own popup.
    function test_anElementCanNarrowThePopupTriggerToAPartOfIt() {
        compare(BarLayout.trigger({ x: 100, y: 6, width: 200, height: 28 }, { x: 40, y: 2, width: 60, height: 24 }),
            { x: 140, y: 8, width: 60, height: 24 });
    }

    function test_anElementRunsItsLengthAlongTheBar_data() {
        return [
            { tag: "top", size: { width: 30, height: 24 } },
            { tag: "bottom", size: { width: 30, height: 24 } },
            { tag: "left", size: { width: 24, height: 30 } },
            { tag: "right", size: { width: 24, height: 30 } }
        ];
    }

    function test_anElementRunsItsLengthAlongTheBar(data) {
        compare(BarLayout.size({ barPosition: data.tag }, 30, 24), data.size);
    }

    function test_withoutABarPositionAnElementLaysOutLikeOnATopBar() {
        compare(BarLayout.size({}, 30, 24), { width: 30, height: 24 });
    }

    function test_onAnOpaqueBarAnElementFillsTheBarLessItsPadding() {
        compare(BarLayout.elementThickness({ barTransparent: false, barHeight: 40, elementVerticalPadding: 3,
            workspaceButtonSize: 22, pillVerticalPadding: 4 }), 34);
    }

    function test_onATransparentBarAnElementIsAButtonAndItsPadding() {
        compare(BarLayout.elementThickness({ barTransparent: true, barHeight: 40, elementVerticalPadding: 3,
            workspaceButtonSize: 22, pillVerticalPadding: 4 }), 30);
    }

    function test_anElementNeverCollapsesOnAThinBar() {
        compare(BarLayout.elementThickness({ barTransparent: false, barHeight: 4, elementVerticalPadding: 3 }), 1);
    }
}
