import QtQuick
import QtTest
import "../components/panels" as Panels
import "../config" as Config

// The Wallpapers section built from the settings parts: the monitor to edit
// is a segmented choice, the wallpaper list stays full width, and the
// Locations and Schedule views use the plain settings parts.
TestCase {
    name: "WallpaperSettings"
    width: 800
    height: 1200
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

    // The settings panel's page: the section sizes itself to it. Fake
    // wallpapers stand in for the shell's and record what is applied; the
    // folders are plain lists of file names.
    Component {
        id: page

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
                }
                wallpapers: wallpapers
                displays: [
                    { description: "AOC", portrait: false },
                    { description: "Philips", portrait: true }
                ]
            }
        }
    }

    function make() {
        const built = createTemporaryObject(page, this);
        return { wallpapers: built.wallpapers, item: built.section };
    }

    function test_theMonitorPickerIsASegmentedChoiceOfTheConnectedDisplays() {
        const built = make();
        const choice = monitorChoice(built.item);

        verify(choice);
        compare(choice.options.map(option => option.value), ["AOC", "Philips"]);
        compare(choice.value, "AOC");
        compare(textOf(choice, "󰍺 AOC").color, theme.accent);
        verify(textOf(choice, "󰍹 Philips"));
    }

    function test_choosingAMonitorShowsTheWallpapersOfItsOrientation() {
        const built = make();

        compare(tiles(built.item).map(tile => tile.wallpaperPath).sort(),
            ["/walls/h/forest.png", "/walls/h/lake.jpg"]);

        monitorChoice(built.item).chosen("Philips");

        compare(monitorChoice(built.item).value, "Philips");
        compare(tiles(built.item).map(tile => tile.wallpaperPath), ["/walls/v/tower.png"]);
    }
}
