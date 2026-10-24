import QtQuick
import QtTest
import "../components/panels" as Panels
import "../config" as Config

// One monitor's settings in the Displays section, built from the settings
// parts: its workspace range as number cells and its shell visibility as
// switch rows, two per line, and the bar profile it draws as a choice.
TestCase {
    name: "MonitorDisplaySettings"
    width: 800
    height: 800
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

    function numberCell(item, label) {
        return all(item, child => child.label === label && child.field !== undefined)[0];
    }

    function switchRow(item, label) {
        return all(item, child => child.label === label && child.switchItem !== undefined)[0];
    }

    // The settings panel's page: the monitor's settings size themselves to
    // it. Fake appearance and monitors stand in for the shell's and record
    // what is saved.
    Component {
        id: page

        Item {
            property alias monitors: monitors
            property alias section: section

            width: 700

            QtObject {
                id: appearance

                property int radius: 12
                property int textSize: 13
                property var barProfiles: ({ main: {}, laptop: {} })
            }

            QtObject {
                id: monitors

                property var saved: []

                function rangeFor(name) {
                    return { from: 3, to: 7 };
                }

                function displaySettingsFor(name) {
                    return { barVisible: true, barProfile: "laptop" };
                }

                function setRangeStart(name, from) {
                    saved = saved.concat([[name, "from", from]]);
                }

                function setRangeEnd(name, to) {
                    saved = saved.concat([[name, "to", to]]);
                }

                function setDisplaySetting(name, setting, value) {
                    saved = saved.concat([[name, setting, value]]);
                }
            }

            Panels.MonitorDisplaySettings {
                id: section

                appearance: appearance
                monitors: monitors
                monitorDescription: "Dell U2720Q"
            }
        }
    }

    function make() {
        const built = createTemporaryObject(page, this);
        return { monitors: built.monitors, item: built.section };
    }

    function sameLine(item, first, second) {
        const a = first.mapToItem(item, 0, 0);
        const b = second.mapToItem(item, 0, 0);
        return a.y === b.y && a.x < b.x;
    }

    function test_theWorkspaceRangeIsTwoNumberCellsOnOneLine() {
        const built = make();
        const first = numberCell(built.item, "First workspace");
        const last = numberCell(built.item, "Last workspace");

        verify(first);
        verify(last);
        verify(sameLine(built.item, first, last));
        compare(first.value, 3);
        compare(last.value, 7);
    }

    function test_typingTheFirstWorkspaceStillSavesIt() {
        const built = make();
        const first = numberCell(built.item, "First workspace");

        first.field.forceActiveFocus();
        first.field.selectAll();
        keyClick("2");
        keyClick(Qt.Key_Return);

        compare(built.monitors.saved, [["Dell U2720Q", "from", 2]]);
    }

    // The slider shows the usual workspaces, but the range has no upper limit:
    // a larger number can still be typed.
    function test_aWorkspacePastTheSliderCanBeTyped() {
        const built = make();
        const last = numberCell(built.item, "Last workspace");

        last.field.forceActiveFocus();
        last.field.selectAll();
        keyClick("4");
        keyClick("2");
        keyClick(Qt.Key_Return);

        compare(built.monitors.saved, [["Dell U2720Q", "to", 42]]);
    }

    function test_aWorkspaceBelowOneIsRejected() {
        const built = make();
        const first = numberCell(built.item, "First workspace");

        first.field.forceActiveFocus();
        first.field.selectAll();
        keyClick("0");
        keyClick(Qt.Key_Return);

        compare(built.monitors.saved, []);
    }

    function test_movingTheLastWorkspaceSliderStillSavesIt() {
        const built = make();
        const last = numberCell(built.item, "Last workspace");

        last.slider.forceActiveFocus();
        keyClick(Qt.Key_Right);

        compare(built.monitors.saved, [["Dell U2720Q", "to", 8]]);
    }

    function test_showingTheBarIsATransparentSwitchRowInTheGridThatSavesWhenToggled() {
        const built = make();
        const bar = switchRow(built.item, "Show bar");
        const grid = all(built.item, child => child.cellWidth !== undefined)[0];

        verify(bar);
        compare(bar.parent, grid);
        compare(bar.width, grid.cellWidth);
        compare(bar.color, Qt.rgba(0, 0, 0, 0));
        verify(bar.checked);

        bar.toggled();
        compare(built.monitors.saved, [["Dell U2720Q", "barVisible", false]]);
    }

    function test_theBarProfileIsAChoiceThatMarksTheDrawnOneAndSavesTheChosenOne() {
        const built = make();
        const choice = all(built.item, child => child.options !== undefined && child.chosen !== undefined)[0];

        verify(choice);
        compare(choice.options, [{ label: "Laptop", value: "laptop" }, { label: "Main", value: "main" }]);
        compare(textOf(choice, "Laptop").color, theme.accent);

        choice.chosen("main");
        compare(built.monitors.saved, [["Dell U2720Q", "barProfile", "main"]]);
    }

    function test_noFilledCardsAndNothingBold() {
        const built = make();
        const bold = all(built.item, child => child.font !== undefined && child.font.bold);
        const filled = all(built.item, child => child instanceof Rectangle && child.radius > 0
            && child.color.a > 0 && child.height >= 32);

        compare(bold.length, 0);
        compare(filled.length, 0);
    }
}
