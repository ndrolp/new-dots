import QtQuick
import QtTest
import "../config/ControlCenterTiles.js" as ControlCenterTiles

// The control center's tile list: one global ordered list where each tile
// can be hidden and moved. The first 6 visible tiles form the collapsed
// control center's row; the expanded one shows every visible tile.
TestCase {
    name: "ControlCenterTiles"

    function tiles(spec) {
        // "wifi,-bluetooth" → wifi shown, bluetooth hidden.
        return spec.split(",").map(entry => entry[0] === "-"
            ? { id: entry.slice(1), enabled: false } : { id: entry, enabled: true });
    }

    function test_theDefaultOrderStartsWithTheQuickTiles() {
        compare(ControlCenterTiles.visibleTiles(ControlCenterTiles.defaultTiles()),
            ["wifi", "bluetooth", "doNotDisturb", "microphone", "keepAwake", "nightLight",
                "audioOutput", "lock", "displaysOff", "powerProfile", "screenCapture",
                "clipboard", "power", "capsLock"]);
    }

    function test_theCollapsedRowIsTheFirstSixVisibleTiles() {
        const list = tiles("lock,-wifi,bluetooth,power,-clipboard,capsLock,microphone,"
            + "nightLight,keepAwake");

        compare(ControlCenterTiles.collapsedTiles(list),
            ["lock", "bluetooth", "power", "capsLock", "microphone", "nightLight"]);
    }

    function test_theCollapsedRowHasFewerTilesWhenFewerAreVisible() {
        compare(ControlCenterTiles.collapsedTiles(tiles("wifi,-lock,power")), ["wifi", "power"]);
    }

    function test_theExpandedStageShowsEveryVisibleTileInOrder() {
        compare(ControlCenterTiles.visibleTiles(tiles("power,-wifi,lock,-bluetooth,capsLock")),
            ["power", "lock", "capsLock"]);
    }

    // A stored list from another version: tiles the shell no longer has go
    // away, new tiles are added shown at the end, duplicates count once.
    function test_aStoredListIsCompletedWithTheTilesItLacks() {
        const stored = tiles("power,-wifi,gone,lock,power");
        const complete = ControlCenterTiles.completeTiles(stored);

        compare(complete.slice(0, 3), tiles("power,-wifi,lock"));
        compare(complete.length, ControlCenterTiles.tileIds.length);
        compare(complete[3], { id: "bluetooth", enabled: true });
        compare(complete[complete.length - 1], { id: "capsLock", enabled: true });
    }

    function test_noStoredListIsTheDefaultOrder() {
        compare(ControlCenterTiles.completeTiles(undefined), ControlCenterTiles.defaultTiles());
    }

    function test_hidingATileTakesItOutOfTheCollapsedRow() {
        const list = ControlCenterTiles.setTileEnabled(ControlCenterTiles.defaultTiles(),
            "bluetooth", false);

        compare(ControlCenterTiles.collapsedTiles(list),
            ["wifi", "doNotDisturb", "microphone", "keepAwake", "nightLight", "audioOutput"]);
        compare(ControlCenterTiles.setTileEnabled(list, "bluetooth", true),
            ControlCenterTiles.defaultTiles());
    }

    function test_movingATileSwapsItWithItsNeighbour() {
        const list = tiles("wifi,-lock,power");

        compare(ControlCenterTiles.moveTile(list, "power", -1), tiles("wifi,power,-lock"));
        compare(ControlCenterTiles.moveTile(list, "wifi", 1), tiles("-lock,wifi,power"));
    }

    function test_movingPastAnEndChangesNothing() {
        const list = tiles("wifi,-lock,power");

        compare(ControlCenterTiles.moveTile(list, "wifi", -1), list);
        compare(ControlCenterTiles.moveTile(list, "power", 1), list);
    }

    // The settings section draws "Collapsed row above" after the 6th visible
    // tile.
    function test_theDividerSitsAfterTheSixthVisibleTile() {
        const list = tiles("wifi,-lock,bluetooth,power,capsLock,microphone,nightLight,keepAwake");

        compare(ControlCenterTiles.dividerAfter(list), "nightLight");
    }

    function test_withFewerThanSixVisibleTilesThereIsNoDivider() {
        compare(ControlCenterTiles.dividerAfter(tiles("wifi,-lock,power")), "");
    }
}
