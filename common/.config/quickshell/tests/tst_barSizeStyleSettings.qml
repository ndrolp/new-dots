import QtQuick
import QtTest
import "../components/panels" as Panels
import "../config" as Config

// The Bar section's Style, Bar and Groups cards, built from the settings
// parts: number settings and switches two per line, paired by meaning, and
// the density presets, the Bar position and the bar style as segmented choices.
TestCase {
    name: "BarSizeStyleSettings"
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

    function numberCell(item, label) {
        return all(item, child => child.label === label && child.field !== undefined)[0];
    }

    function switchRow(item, label) {
        return all(item, child => child.label === label && child.switchItem !== undefined)[0];
    }

    // Where the settings panel shows a section: the section sizes itself to it. A
    // fake appearance stands in for the shell's and records what is saved.
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
                property int iconSize: 13
                property string barPosition: "top"
                property int barHeight: 32
                property int barOpacity: 90
                property int horizontalPadding: 12
                property int pillVerticalPadding: 4
                property int elementVerticalPadding: 4
                property int transparentBarTopMargin: 8
                property int groupRadius: 16
                property int spacing: 8
                property int groupHorizontalPadding: 8
                property int groupVerticalPadding: 0
                property string barStyle: "opaque"
                property bool barBorder: false
                property bool elementBorder: false
                property bool groupBorder: false
                property bool pillsTransparent: false
                property bool capsuleNotifications: false
                property string matchingDensityPreset: "balanced"
                property var motion: ({ short: 0 })
                property var saved: []
                property var appliedPresets: []

                function setBarSetting(name, value) {
                    saved = saved.concat([[name, value]]);
                }

                function applyDensityPreset(preset) {
                    appliedPresets = appliedPresets.concat([preset]);
                }
            }

            Panels.BarSizeStyleSettings {
                id: section

                appearance: appearance
            }
        }
    }

    function make() {
        const built = createTemporaryObject(sectionArea, this);
        return { appearance: built.appearance, item: built.section };
    }

    function sameLine(item, first, second) {
        const a = first.mapToItem(item, 0, 0);
        const b = second.mapToItem(item, 0, 0);
        return a.y === b.y && a.x < b.x;
    }

    function test_numberSettingsSitTwoPerLinePairedByMeaning() {
        const built = make();
        const pairs = [
            ["Bar thickness", "Bar opacity"],
            ["Corner radius", "Horizontal padding"],
            ["Group radius", "Group horizontal padding"]
        ];

        for (const pair of pairs) {
            const first = numberCell(built.item, pair[0]);
            const second = numberCell(built.item, pair[1]);
            verify(first, pair[0]);
            verify(second, pair[1]);
            verify(sameLine(built.item, first, second), pair.join(" | "));
        }
    }

    function test_typingABarSizeStillSavesIt() {
        const built = make();
        const cell = numberCell(built.item, "Bar thickness");

        cell.field.forceActiveFocus();
        cell.field.selectAll();
        keyClick("4");
        keyClick("0");
        keyClick(Qt.Key_Return);

        compare(built.appearance.saved, [["barHeight", 40]]);
    }

    function test_movingABarSizeSliderStillSavesIt() {
        const built = make();
        const cell = numberCell(built.item, "Group radius");

        cell.slider.forceActiveFocus();
        keyClick(Qt.Key_Right);

        compare(built.appearance.saved, [["groupRadius", 17]]);
    }

    // A switch shares a line with the number before it.
    function test_borderSwitchesSitBesideANumberAndSaveWhenToggled() {
        const built = make();
        const border = switchRow(built.item, "Bar border");
        const groupBorder = switchRow(built.item, "Group border");

        verify(sameLine(built.item, numberCell(built.item, "Vertical padding"), border));
        verify(sameLine(built.item, numberCell(built.item, "Group vertical padding"), groupBorder));
        compare(border.color, Qt.rgba(0, 0, 0, 0));

        border.toggled();
        groupBorder.toggled();
        compare(built.appearance.saved, [["barBorder", true], ["groupBorder", true]]);
    }

    function test_theMatchingDensityPresetIsMarkedAndChoosingOneFillsInTheSizes() {
        const built = make();
        const field = all(built.item, child => child.label === "Density preset" && child.small !== undefined)[0];
        const choice = all(field, child => child.options !== undefined && child.chosen !== undefined)[0];

        compare(choice.value, "balanced");
        compare(textOf(choice, "Balanced").color, theme.accent);

        choice.chosen("spacious");
        compare(built.appearance.appliedPresets, ["spacious"]);
    }

    function positionChoice(item) {
        const field = all(item, child => child.label === "Bar position" && child.small !== undefined)[0];
        return field ? all(field, child => child.options !== undefined && child.chosen !== undefined)[0] : null;
    }

    function styleChoice(item) {
        const field = all(item, child => child.label === "Bar style" && child.small !== undefined)[0];
        return field ? all(field, child => child.options !== undefined && child.chosen !== undefined)[0] : null;
    }

    function test_theBarStyleIsOneChoiceOfEveryStyle() {
        const built = make();
        const choice = styleChoice(built.item);

        verify(choice);
        compare(choice.options.map(option => option.value), ["opaque", "transparent", "docked", "capsule"]);
        compare(choice.options.map(option => option.label), ["Opaque", "Transparent", "Docked", "Capsule"]);
        verify(!switchRow(built.item, "Transparent bar"));
        verify(!switchRow(built.item, "Docked bar"));
    }

    function test_theCurrentBarStyleIsMarkedAndChoosingOneSavesIt() {
        const built = make();
        const choice = styleChoice(built.item);

        compare(textOf(choice, "Opaque").color, theme.accent);

        built.appearance.barStyle = "docked";
        compare(textOf(choice, "Docked").color, theme.accent);

        choice.chosen("transparent");
        compare(built.appearance.saved, [["barStyle", "transparent"]]);
    }

    function test_theBarStyleOffersEveryStyle() {
        const choice = styleChoice(make().item);

        compare(choice.options.map(option => option.value), ["opaque", "transparent", "docked", "capsule"]);
        compare(choice.options.map(option => option.label), ["Opaque", "Transparent", "Docked", "Capsule"]);
    }

    function test_theBarPositionOffersAllFourPositions() {
        const choice = positionChoice(make().item);

        verify(choice);
        compare(choice.options.map(option => option.value), ["top", "bottom", "left", "right"]);
        compare(choice.options.map(option => option.label), ["Top", "Bottom", "Left", "Right"]);
    }

    // A capsule sits only at the top or the bottom of its screen.
    function test_aCapsuleOffersOnlyTheTopAndBottomPositions() {
        const built = make();
        const choice = positionChoice(built.item);

        built.appearance.barStyle = "capsule";
        compare(choice.options.map(option => option.label), ["Top", "Bottom"]);

        choice.chosen("bottom");
        compare(built.appearance.saved, [["barPosition", "bottom"]]);

        built.appearance.barStyle = "docked";
        compare(choice.options.map(option => option.label), ["Top", "Bottom", "Left", "Right"]);
    }

    function test_aSideBarPositionIsMarkedAndSaved_data() {
        return [
            { tag: "left", position: "left", label: "Left" },
            { tag: "right", position: "right", label: "Right" }
        ];
    }

    function test_aSideBarPositionIsMarkedAndSaved(data) {
        const built = make();
        const choice = positionChoice(built.item);

        built.appearance.barPosition = data.position;
        compare(textOf(choice, data.label).color, theme.accent);

        choice.chosen(data.position);
        compare(built.appearance.saved, [["barPosition", data.position]]);
    }

    function test_theCurrentBarPositionIsMarkedAndChoosingOneSavesIt() {
        const built = make();
        const choice = positionChoice(built.item);

        compare(choice.value, "top");
        compare(textOf(choice, "Top").color, theme.accent);

        built.appearance.barPosition = "bottom";
        compare(textOf(choice, "Bottom").color, theme.accent);

        choice.chosen("top");
        compare(built.appearance.saved, [["barPosition", "top"]]);
    }

    // Both keep their saved keys: thickness and the gap from the screen edge
    // (the edge margin, stored as the transparent bar margin) read the same
    // on every Bar position. A transparent bar keeps that gap.
    function test_theBarSizesAreNamedForEveryBarPosition() {
        const built = make();
        built.appearance.barStyle = "transparent";
        const margin = numberCell(built.item, "Edge margin");

        verify(numberCell(built.item, "Bar thickness"));
        verify(!numberCell(built.item, "Transparent bar margin"));
        verify(margin);
        compare(margin.value, 8);
    }

    function test_nothingInTheseGroupsIsBold() {
        const built = make();
        const bold = all(built.item, child => child.font !== undefined && child.font.bold);

        compare(bold.length, 0);
    }
}
