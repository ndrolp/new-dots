import QtQuick
import QtTest
import "../components/panels" as Panels
import "../config/ControlCenterTiles.js" as ControlCenterTiles
import "../config/Motion.js" as Motion

// The Control center section: every tile of the control center in its order,
// each with a switch and move arrows, and a "Collapsed row above" divider
// after the 6th visible tile.
TestCase {
    name: "ControlCenterSettings"
    width: 800
    height: 1200
    when: windowShown
    // Shown, so that `visible` tells which rows are shown.
    visible: true

    function all(item, predicate, found) {
        found = found || [];
        if (predicate(item))
            found.push(item);
        for (let i = 0; i < item.children.length; i++)
            all(item.children[i], predicate, found);
        return found;
    }

    function rows(item) {
        // A changed list rebuilds the rows; wait until the Column has laid them out.
        wait(0);
        return all(item, child => child.tileLabel !== undefined && child.visible)
            .sort((a, b) => yOf(a) - yOf(b));
    }

    function row(item, label) {
        return rows(item).find(candidate => candidate.tileLabel === label) || null;
    }

    function labels(item) {
        return rows(item).map(candidate => candidate.tileLabel);
    }

    function switchOf(rowItem) {
        return all(rowItem, child => child.checked !== undefined && child.border !== undefined)[0];
    }

    function button(item, label) {
        return all(item, child => child.label === label && child.activated !== undefined)[0];
    }

    function divider(item) {
        wait(0);
        return all(item, child => child.text === "Collapsed row above" && child.visible)[0]
            || null;
    }

    function yOf(item) {
        return item.mapToItem(null, 0, 0).y;
    }

    // Where the settings panel shows a section. The fake appearance keeps the
    // tile list as the shell's does.
    Component {
        id: sectionArea

        Item {
            property alias appearance: appearance
            property alias section: section

            width: 700

            QtObject {
                id: appearance

                property int radius: 12
                property int textSize: 13
                readonly property var motion: Motion.motion(true)
                property var storedTiles: ControlCenterTiles.defaultTiles()
                readonly property var controlCenterTiles: ControlCenterTiles.completeTiles(storedTiles)

                function setControlCenterTileEnabled(tile, enabled) {
                    storedTiles = ControlCenterTiles.setTileEnabled(controlCenterTiles, tile, enabled);
                }

                function moveControlCenterTile(tile, offset) {
                    storedTiles = ControlCenterTiles.moveTile(controlCenterTiles, tile, offset);
                }
            }

            Panels.ControlCenterSettings {
                id: section

                appearance: appearance
            }
        }
    }

    function make(tiles) {
        const built = createTemporaryObject(sectionArea, this);
        if (tiles)
            built.appearance.storedTiles = tiles;
        return built;
    }

    function test_everyTileIsListedInItsOrder() {
        const built = make();

        compare(labels(built.section), ["Wi-Fi", "Bluetooth", "Do not disturb", "Microphone",
            "Keep-awake", "Night light", "Audio output", "Lock", "Displays off",
            "Power profile", "Screen capture", "Clipboard", "Power menu", "Caps Lock"]);
    }

    function test_theSwitchShowsWhetherATileIsShown() {
        const built = make([{ id: "lock", enabled: false }]);

        compare(switchOf(row(built.section, "Lock")).checked, false);
        compare(switchOf(row(built.section, "Wi-Fi")).checked, true);
    }

    function test_theSwitchHidesAndShowsATile() {
        const built = make();

        mouseClick(switchOf(row(built.section, "Bluetooth")));
        compare(ControlCenterTiles.visibleTiles(built.appearance.controlCenterTiles).indexOf("bluetooth"),
            -1);
        compare(switchOf(row(built.section, "Bluetooth")).checked, false);

        mouseClick(switchOf(row(built.section, "Bluetooth")));
        compare(switchOf(row(built.section, "Bluetooth")).checked, true);
    }

    function test_theArrowsMoveATileAndTheListFollows() {
        const built = make();

        button(row(built.section, "Bluetooth"), "󰁝").activated();
        compare(labels(built.section).slice(0, 2), ["Bluetooth", "Wi-Fi"]);

        button(row(built.section, "Bluetooth"), "󰁅").activated();
        compare(labels(built.section).slice(0, 2), ["Wi-Fi", "Bluetooth"]);
    }

    function test_theEndsOfTheListCannotMovePastThem() {
        const built = make();

        compare(button(row(built.section, "Wi-Fi"), "󰁝").enabled, false);
        compare(button(row(built.section, "Caps Lock"), "󰁅").enabled, false);
        compare(button(row(built.section, "Lock"), "󰁝").enabled, true);
    }

    function test_theDividerSitsAfterTheSixthVisibleTile() {
        // Bluetooth hidden: the 6th visible tile is Audio output.
        const built = make([{ id: "wifi", enabled: true }, { id: "bluetooth", enabled: false }]);
        const line = divider(built.section);

        verify(line);
        verify(yOf(line) > yOf(row(built.section, "Audio output")));
        verify(yOf(line) < yOf(row(built.section, "Lock")));
    }

    function test_theDividerFollowsWhenATileIsHidden() {
        const built = make();

        verify(yOf(divider(built.section)) < yOf(row(built.section, "Audio output")));
        mouseClick(switchOf(row(built.section, "Wi-Fi")));
        verify(yOf(divider(built.section)) > yOf(row(built.section, "Audio output")));
        verify(yOf(divider(built.section)) < yOf(row(built.section, "Lock")));
    }

    function test_withFewerThanSixVisibleTilesThereIsNoDivider() {
        const built = make(ControlCenterTiles.tileIds.map((id, index) => ({ id: id,
            enabled: index < 5 })));

        compare(divider(built.section), null);
    }
}
