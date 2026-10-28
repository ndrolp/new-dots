import QtQuick
import QtTest
import "../components/panels" as Panels
import "../config/Motion.js" as Motion
import "../config" as Config

// The Wallpapers section built from the settings parts: the monitor to edit
// is a segmented choice, the wallpaper list stays full width, and the
// Locations and Schedule views use the plain settings parts.
TestCase {
    name: "WallpaperSettings"
    width: 800
    height: 1200
    visible: true
    when: windowShown

    Config.Theme {
        id: theme
    }

    function all(item, predicate, found) {
        found = found || [];
        if (predicate(item))
            found.push(item);
        for (let i = 0; i < item.children.length; i++)
            all(item.children[i], predicate, found);
        return found;
    }

    function textOf(item, text) {
        return all(item, child => child.text === text && child.font !== undefined
            && !(child instanceof TextInput))[0] || null;
    }

    function choices(item) {
        return all(item, child => child.options !== undefined && child.chosen !== undefined);
    }

    function monitorChoice(item) {
        return choices(item).filter(choice => choice.options.some(option => option.value === "AOC"))[0];
    }

    function viewChoice(item) {
        return choices(item).filter(choice => choice.options.some(option => option.value === "Schedule"))[0];
    }

    function tiles(item) {
        return all(item, child => child.wallpaperPath !== undefined);
    }

    // Where the settings panel shows a section: the section sizes itself to it.
    // Fake wallpapers stand in for the shell's and record what is applied; the
    // folders are plain lists of file names.
    Component {
        id: sectionArea

        Item {
            property alias wallpapers: wallpapers
            property alias section: section

            width: 700

            ListModel {
                id: horizontalFiles

                ListElement { fileName: "forest.png" }
                ListElement { fileName: "lake.jpg" }
            }

            ListModel {
                id: verticalFiles

                ListElement { fileName: "tower.png" }
            }

            QtObject {
                id: wallpapers

                property string horizontalFolder: "/walls/h"
                property string verticalFolder: "/walls/v"
                property bool dynamicEnabled: false
                property int dynamicIntervalMinutes: 30
                property var horizontalWallpapers: horizontalFiles
                property var verticalWallpapers: verticalFiles
                property var assignments: ({ "AOC": "/walls/h/lake.jpg" })
                property var applied: []
                property int advanced: 0

                function pathFor(description) {
                    return assignments[description] || "";
                }

                function setWallpaper(description, path) {
                    applied = applied.concat([[description, path]]);
                }

                function advanceAll() {
                    advanced += 1;
                }
            }

            Panels.WallpaperSettingsBody {
                id: section

                appearance: QtObject {
                    property int radius: 12
                    property int textSize: 13
                    readonly property var motion: Motion.motion(false)
                }
                wallpapers: wallpapers
                displays: [
                    { description: "AOC", name: "Q27G2", portrait: false },
                    { description: "Philips", name: "243V", portrait: true }
                ]
            }
        }
    }

    function make() {
        const built = createTemporaryObject(sectionArea, this);
        return { wallpapers: built.wallpapers, item: built.section };
    }

    function test_theMonitorPickerIsASegmentedChoiceOfTheConnectedDisplays() {
        const built = make();
        const choice = monitorChoice(built.item);

        verify(choice);
        compare(choice.options.map(option => option.value), ["AOC", "Philips"]);
        compare(choice.value, "AOC");
        compare(textOf(choice, "󰍺 Q27G2").color, theme.accent);
        verify(textOf(choice, "󰍹 243V"));
    }

    function test_choosingAMonitorShowsTheWallpapersOfItsOrientation() {
        const built = make();

        compare(tiles(built.item).map(tile => tile.wallpaperPath).sort(),
            ["/walls/h/forest.png", "/walls/h/lake.jpg"]);

        monitorChoice(built.item).chosen("Philips");

        compare(monitorChoice(built.item).value, "Philips");
        compare(tiles(built.item).map(tile => tile.wallpaperPath), ["/walls/v/tower.png"]);
    }

    function test_theViewsAreASegmentedChoiceThatSwitchesWhatIsShown() {
        const built = make();
        const views = viewChoice(built.item);
        const list = all(built.item, child => child instanceof GridView)[0];

        compare(views.options.map(option => option.label), ["Selection", "Locations", "Schedule"]);
        compare(views.value, "Selection");
        verify(list.visible);

        views.chosen("Locations");

        compare(views.value, "Locations");
        verify(!list.visible);
        verify(textOf(built.item, "Wallpaper folders").visible);
    }

    // A folder is saved when its edit is finished, not on every key.
    function test_typingAFolderSavesItWhenFinished() {
        const built = make();
        viewChoice(built.item).chosen("Locations");
        const folder = all(built.item, child => child instanceof TextInput
            && child.placeholderText === "Horizontal wallpaper folder")[0];

        folder.forceActiveFocus();
        folder.selectAll();
        keyClick("x");
        compare(built.wallpapers.horizontalFolder, "/walls/h");
        keyClick(Qt.Key_Return);

        compare(built.wallpapers.horizontalFolder, "x");
    }

    function test_withoutMonitorsTheSelectionSaysNoneAreConfigured() {
        const built = make();
        built.item.displays = [];

        verify(textOf(built.item, "No monitors configured").visible);
    }

    function test_theScheduleIsASwitchRowANumberAndAQuietButton() {
        const built = make();
        viewChoice(built.item).chosen("Schedule");
        const rotation = all(built.item, child => child.label === "Enable scheduled rotation"
            && child.switchItem !== undefined)[0];
        const interval = all(built.item, child => child.label === "Interval (minutes)"
            && child.field !== undefined)[0];
        const advance = all(built.item, child => child.label === "Advance now"
            && child.activated !== undefined)[0];

        compare(rotation.color, Qt.rgba(0, 0, 0, 0));
        rotation.toggled();
        verify(built.wallpapers.dynamicEnabled);
        verify(rotation.checked);

        compare(interval.from, 1);
        compare(interval.to, 240);
        compare(interval.field.text, "30");
        interval.edited(45);
        compare(built.wallpapers.dynamicIntervalMinutes, 45);

        compare(advance.color, Qt.rgba(0, 0, 0, 0));
        advance.activated();
        compare(built.wallpapers.advanced, 1);
    }

    function test_theListIsHeadedByTheMonitorsOrientation() {
        const built = make();

        verify(textOf(built.item, "Horizontal wallpapers").visible);

        monitorChoice(built.item).chosen("Philips");

        verify(textOf(built.item, "Vertical wallpapers").visible);
    }

    function test_nothingInTheSectionIsBold() {
        const built = make();
        const bold = all(built.item, child => child.font !== undefined && child.font.bold);

        compare(bold.length, 0);
    }

    function test_theWallpaperListStaysFullWidth() {
        const built = make();
        const list = all(built.item, child => child instanceof GridView)[0];

        compare(list.width, built.item.width);
    }

    function test_choosingAWallpaperAppliesItToTheChosenMonitor() {
        const built = make();
        monitorChoice(built.item).chosen("Philips");
        const tower = tiles(built.item)[0];

        mouseClick(tower);

        compare(built.wallpapers.applied, [["Philips", "/walls/v/tower.png"]]);
    }

    function test_theMonitorsWallpaperIsOutlinedAndNoTileIsAFilledCard() {
        const built = make();
        const lake = tiles(built.item).filter(tile => tile.wallpaperPath === "/walls/h/lake.jpg")[0];
        const forest = tiles(built.item).filter(tile => tile.wallpaperPath === "/walls/h/forest.png")[0];

        compare(lake.border.color, theme.accent);
        compare(forest.border.color, theme.border);
        compare(lake.color, Qt.rgba(0, 0, 0, 0));
        compare(forest.color, Qt.rgba(0, 0, 0, 0));
    }
}
