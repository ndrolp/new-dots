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
}
