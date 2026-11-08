import QtQuick
import QtTest
import "../config/DesktopWidgetsModel.js" as DesktopWidgetsModel

// Where a desktop widget sits on its monitor is stored as one position,
// "top-left", "center-right"…, or just "center" in the middle; the settings
// choose it as a row (top, center, bottom) and a column (left, center, right).
TestCase {
    name: "DesktopWidgetsPlacement"

    function test_aPositionSplitsIntoItsRowAndColumn() {
        compare(DesktopWidgetsModel.placementOf("top-left"), { vertical: "top", horizontal: "left" });
        compare(DesktopWidgetsModel.placementOf("center-right"), { vertical: "center", horizontal: "right" });
        compare(DesktopWidgetsModel.placementOf("bottom-center"), { vertical: "bottom", horizontal: "center" });
    }

    function test_theMiddleIsTheCenterRowAndColumn() {
        compare(DesktopWidgetsModel.placementOf("center"), { vertical: "center", horizontal: "center" });
    }

    function test_aRowAndColumnJoinIntoOnePosition() {
        compare(DesktopWidgetsModel.positionOf("top", "left"), "top-left");
        compare(DesktopWidgetsModel.positionOf("center", "right"), "center-right");
        compare(DesktopWidgetsModel.positionOf("bottom", "center"), "bottom-center");
    }

    function test_theCenterRowAndColumnAreJustCenter() {
        compare(DesktopWidgetsModel.positionOf("center", "center"), "center");
    }

    // The window of a monitor's desktop widgets fills the area the bar leaves
    // free, so these are plain gaps from that area, wherever the bar is.
    readonly property var area: ({ width: 1000, height: 600 })
    readonly property var card: ({ width: 200, height: 70 })

    function test_aCardKeepsItsGapFromTheAreasCorners() {
        const alone = { offset: 0, height: 70 };

        compare(DesktopWidgetsModel.cardPosition("top-left", card, area, alone), { x: 28, y: 28 });
        compare(DesktopWidgetsModel.cardPosition("top-right", card, area, alone), { x: 772, y: 28 });
        compare(DesktopWidgetsModel.cardPosition("bottom-left", card, area, alone), { x: 28, y: 494 });
        compare(DesktopWidgetsModel.cardPosition("bottom-right", card, area, alone), { x: 772, y: 494 });
    }

    function test_aCardStacksAwayFromItsEdge() {
        const second = { offset: 80, height: 150 };

        compare(DesktopWidgetsModel.cardPosition("top-center", card, area, second), { x: 400, y: 108 });
        compare(DesktopWidgetsModel.cardPosition("bottom-center", card, area, second), { x: 400, y: 414 });
    }

    function test_theCenterRowCentersTheWholeStack() {
        compare(DesktopWidgetsModel.cardPosition("center", card, area, { offset: 80, height: 150 }),
            { x: 400, y: 305 });
        compare(DesktopWidgetsModel.cardPosition("center-right", card, area, { offset: 0, height: 70 }),
            { x: 772, y: 265 });
    }

    function test_theBackgroundClockKeepsItsOwnGapFromTheArea() {
        const clock = { width: 300, height: 120 };

        compare(DesktopWidgetsModel.clockPosition("top-left", clock, area), { x: 48, y: 48 });
        compare(DesktopWidgetsModel.clockPosition("bottom-right", clock, area), { x: 652, y: 424 });
        compare(DesktopWidgetsModel.clockPosition("center", clock, area), { x: 350, y: 240 });
    }

    function test_theEdgePaddingMovesTheCardsAndTheClockFromTheEdges() {
        const area = { width: 1000, height: 600 };
        const card = { width: 200, height: 70 };
        const alone = { offset: 0, height: 70 };

        compare(DesktopWidgetsModel.cardPosition("top-left", card, area, alone, 60), { x: 60, y: 60 });
        compare(DesktopWidgetsModel.cardPosition("bottom-right", card, area, alone, 0), { x: 800, y: 522 });
        compare(DesktopWidgetsModel.clockPosition("top-left", card, area, 0), { x: 20, y: 20 });
        compare(DesktopWidgetsModel.clockPosition("top-left", card, area, 60), { x: 80, y: 80 });
    }

    function test_theEdgePaddingIsKeptPerMonitorAndWithinItsRange() {
        let settings = DesktopWidgetsModel.setEdgePadding({}, "HDMI-9", 64);

        compare(DesktopWidgetsModel.desktopWidgetsFor(settings, "HDMI-9").edgePadding, 64);
        compare(DesktopWidgetsModel.desktopWidgetsFor(settings, "DP-1").edgePadding, 28);
        settings = DesktopWidgetsModel.setEdgePadding(settings, "HDMI-9", 900);
        compare(DesktopWidgetsModel.desktopWidgetsFor(settings, "HDMI-9").edgePadding, 200);
        settings = DesktopWidgetsModel.setEdgePadding(settings, "HDMI-9", -4);
        compare(DesktopWidgetsModel.desktopWidgetsFor(settings, "HDMI-9").edgePadding, 0);
    }
}
