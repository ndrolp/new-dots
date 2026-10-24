import QtQuick
import QtTest
import "../components/panels" as Panels
import "../config" as Config

// The Bar section's bar elements list, built from the settings parts: full
// width rows transparent until hovered, the zone as a segmented choice and
// each bar element's options as switch rows.
TestCase {
    name: "BarElementsSettings"
    width: 900
    height: 1600
    when: windowShown
    // Shown, so that `visible` tells which rows are shown.
    visible: true

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
            && !(child instanceof TextInput) && child.visible)[0] || null;
    }

    function elementRow(item, label) {
        return all(item, child => child.elementLabel === label)[0] || null;
    }

    function button(item, label) {
        return all(item, child => child.label === label && child.activated !== undefined
            && child.visible)[0] || null;
    }

    function zoneChoice(item) {
        return all(item, child => child.options !== undefined && child.chosen !== undefined)[0];
    }

    function switchRow(item, label) {
        return all(item, child => child.label === label && child.switchItem !== undefined
            && child.visible)[0] || null;
    }

    // A fake appearance stands in for the shell's and records what is asked.
    Component {
        id: sectionArea

        Item {
            property alias appearance: appearance
            property alias section: section

            width: 800

            QtObject {
                id: appearance

                property int radius: 12
                property int textSize: 13
                property var barElements: ({
                    left: [{ id: "arch", enabled: true }, { id: "workspaces", enabled: true }],
                    center: [{ id: "clock", enabled: true }],
                    right: [
                        { id: "audio", enabled: true, options: { meterVisible: true } },
                        { id: "battery", enabled: false, joinPrevious: true },
                        { id: "cava", enabled: false }
                    ]
                })
                property var calls: []

                function record(call) {
                    calls = calls.concat([call]);
                }

                property var cavaOptions: ({ barCount: 12, barWidth: 3, color: "blue" })

                function barElementOption(element, option) {
                    if (element === "cava")
                        return cavaOptions[option];
                    return element === "audio" && option === "meterVisible";
                }

                function setBarElementOption(element, option, value) {
                    record(["option", element, option, value]);
                }

                function setBarElementEnabled(element, enabled) {
                    record(["enabled", element, enabled]);
                }

                function setBarElementJoined(element, joined) {
                    record(["joined", element, joined]);
                }

                function moveBarElementToZone(element, zone) {
                    record(["zone", element, zone]);
                }

                function moveBarElement(element, offset) {
                    record(["move", element, offset]);
                }
            }

            Panels.BarElementsSettings {
                id: section

                appearance: appearance
            }
        }
    }

    function numberOption(item, label) {
        return all(item, child => child.label === label && child.fieldTo !== undefined
            && child.visible)[0] || null;
    }

    function choiceOption(item, label) {
        const field = all(item, child => child.label === label && child.appearance !== undefined
            && child.fieldTo === undefined && child.switchItem === undefined && child.visible)[0];
        return field ? zoneChoice(field) : null;
    }

    // A test-only bar element whose options mix a switch, a number and a
    // choice, as no real element does yet.
    Component {
        id: probeArea

        Item {
            property alias appearance: appearance
            property alias section: section

            width: 800

            QtObject {
                id: appearance

                property int radius: 12
                property int textSize: 13
                property var barElements: ({
                    left: [],
                    center: [{ id: "probe", enabled: true }],
                    right: []
                })
                property var optionValues: ({ peaksVisible: true, bars: 12, color: "blue" })
                property var calls: []

                function barElementOption(element, option) {
                    return element === "probe" ? optionValues[option] : undefined;
                }

                function setBarElementOption(element, option, value) {
                    calls = calls.concat([["option", element, option, value]]);
                }
            }

            Panels.BarElementsSettings {
                id: section

                appearance: appearance
                elementOptions: ({
                    "probe": [
                        { label: "Show peaks", option: "peaksVisible" },
                        { label: "Bars", option: "bars", kind: "number", from: 6, to: 32 },
                        { label: "Color", option: "color", kind: "choice", choices: [
                            { label: "Blue", value: "blue" },
                            { label: "Red", value: "red" }
                        ] }
                    ]
                })
            }
        }
    }

    function make() {
        const built = createTemporaryObject(sectionArea, this);
        return { appearance: built.appearance, item: built.section };
    }

    function makeProbe() {
        const built = createTemporaryObject(probeArea, this);
        mouseClick(textOf(elementRow(built.section, "probe"), "probe"));
        return { appearance: built.appearance, item: built.section };
    }

    function test_anElementsOptionsCanMixSwitchesNumbersAndChoices() {
        const built = makeProbe();

        verify(switchRow(built.item, "Show peaks").checked);
        compare(numberOption(built.item, "Bars").value, 12);
        compare(choiceOption(built.item, "Color").value, "blue");
    }

    function test_aNumberOptionClampsToItsMinimumAndMaximum() {
        const built = makeProbe();
        const bars = numberOption(built.item, "Bars");

        compare(bars.from, 6);
        compare(bars.to, 32);
        bars.edited(40);
        bars.edited(2);
        bars.edited(20);

        compare(built.appearance.calls, [["option", "probe", "bars", 32], ["option", "probe", "bars", 6],
            ["option", "probe", "bars", 20]]);
    }

    function test_aChoiceOptionOnlyOffersItsListedValues() {
        const built = makeProbe();
        const color = choiceOption(built.item, "Color");

        compare(color.options.map(choice => choice.value), ["blue", "red"]);
        color.chosen("green");
        color.chosen("red");

        compare(built.appearance.calls, [["option", "probe", "color", "red"]]);
    }

    function test_switchOptionsStillToggleNextToNumbersAndChoices() {
        const built = makeProbe();

        switchRow(built.item, "Show peaks").toggled();

        compare(built.appearance.calls, [["option", "probe", "peaksVisible", false]]);
    }

    function test_eachBarElementIsAFullWidthRowTransparentUntilHovered() {
        const built = make();
        const row = elementRow(built.item, "Arch icon");

        verify(row);
        compare(row.width, built.item.width);
        compare(row.color, Qt.rgba(0, 0, 0, 0));
    }

    function test_cavaIsListedByItsName() {
        const built = make();
        const cava = elementRow(built.item, "Cava");

        verify(cava);
        verify(!all(cava, child => child.checked !== undefined && child.toggled === undefined)[0].checked);
    }

    function test_aHintShowsUnderCavaWhileCavaCantRunAndGoesAwayOnceItRuns() {
        const built = make();
        const hint = "cava isn't installed, so the bars stay flat.";

        verify(!textOf(built.item, hint));
        built.item.elementHints = { "cava": hint };
        const shown = textOf(built.item, hint);
        verify(shown);
        tryVerify(() => shown.mapToItem(built.item, 0, 0).y
            > elementRow(built.item, "Cava").mapToItem(built.item, 0, 0).y);

        built.item.elementHints = { "cava": "" };
        verify(!textOf(built.item, hint));
    }

    function test_cavasBarCountWidthAndColorAreEditedUnderIt() {
        const built = make();
        mouseClick(textOf(elementRow(built.item, "Cava"), "Cava"));
        const count = numberOption(built.item, "Bars");
        const width = numberOption(built.item, "Bar width");
        const color = choiceOption(built.item, "Color");

        compare([count.value, count.from, count.to], [12, 6, 32]);
        compare([width.value, width.from, width.to], [3, 1, 8]);
        compare(color.value, "blue");
        compare(color.options.map(choice => choice.value),
            ["accent", "blue", "green", "yellow", "orange", "red", "purple", "text"]);

        count.edited(20);
        width.edited(5);
        color.chosen("red");
        compare(built.appearance.calls, [["option", "cava", "barCount", 20],
            ["option", "cava", "barWidth", 5], ["option", "cava", "color", "red"]]);
    }

    function test_theZonesAreHeadingsWithTheirElementsInOrder() {
        const built = make();
        const left = textOf(built.item, "Left");
        const arch = elementRow(built.item, "Arch icon");
        const workspaces = elementRow(built.item, "Workspaces");

        verify(left);
        compare(left.font.capitalization, Font.AllUppercase);
        verify(left.mapToItem(built.item, 0, 0).y < arch.mapToItem(built.item, 0, 0).y);
        verify(arch.mapToItem(built.item, 0, 0).y < workspaces.mapToItem(built.item, 0, 0).y);
    }

    function test_theSwitchTurnsABarElementOnOrOff() {
        const built = make();
        const battery = elementRow(built.item, "Battery");
        const batterySwitch = all(battery, child => child.checked !== undefined && child.toggled === undefined)[0];

        verify(!batterySwitch.checked);
        mouseClick(batterySwitch);

        compare(built.appearance.calls, [["enabled", "battery", true]]);
    }

    function test_theZoneChoiceMarksTheZoneAndMovesTheElement() {
        const built = make();
        const choice = zoneChoice(elementRow(built.item, "Clock & pomodoro"));

        compare(choice.value, "center");
        choice.chosen("left");

        compare(built.appearance.calls, [["zone", "clock", "left"]]);
    }

    function test_theArrowsReorderWithinTheZone() {
        const built = make();
        const workspaces = elementRow(built.item, "Workspaces");

        button(workspaces, "󰁝").activated();
        button(workspaces, "󰁅").activated();

        compare(built.appearance.calls, [["move", "workspaces", -1], ["move", "workspaces", 1]]);
    }

    function test_theFirstElementOfAZoneCannotMoveUp() {
        const built = make();
        const audio = elementRow(built.item, "Audio");

        verify(!button(audio, "󰁝").enabled);
        verify(button(audio, "󰁅").enabled);
    }

    function test_joinGroupsAnElementWithTheOneAbove() {
        const built = make();
        const battery = elementRow(built.item, "Battery");
        const audio = elementRow(built.item, "Audio");

        verify(!button(audio, "󰌷  Join"), "the first element of a zone cannot join");
        compare(button(battery, "󰌷  Join").labelColor, theme.accent);

        button(battery, "󰌷  Join").activated();
        compare(built.appearance.calls, [["joined", "battery", false]]);
    }

    function test_anElementsOptionsAreSwitchRowsThatSaveToTheProfile() {
        const built = make();

        verify(!switchRow(built.item, "Show volume meter"));
        mouseClick(textOf(elementRow(built.item, "Audio"), "Audio"));

        const meter = switchRow(built.item, "Show volume meter");
        verify(meter);
        verify(meter.checked);
        meter.toggled();

        compare(built.appearance.calls, [["option", "audio", "meterVisible", false]]);
    }

    function test_shortOptionsSitTwoPerLine() {
        const built = make();

        mouseClick(textOf(elementRow(built.item, "Workspaces"), "Workspaces"));

        const hide = switchRow(built.item, "Hide empty workspaces");
        const counts = switchRow(built.item, "Show workspace app counts");
        const a = hide.mapToItem(built.item, 0, 0);
        const b = counts.mapToItem(built.item, 0, 0);
        compare(a.y, b.y);
        verify(a.x < b.x);
    }

    function test_nothingIsBoldOrWrittenInCapitals() {
        const built = make();
        mouseClick(textOf(elementRow(built.item, "Workspaces"), "Workspaces"));
        const loud = all(built.item, child => child.font !== undefined
            && (child.font.bold || (child.text !== undefined && child.text.length > 1
                && child.text === child.text.toUpperCase() && /[A-Z]/.test(child.text))));

        compare(loud.map(child => child.text), []);
    }

    function test_nothingIsAFilledCard() {
        const built = make();
        mouseClick(textOf(elementRow(built.item, "Workspaces"), "Workspaces"));
        const filled = all(built.item, child => child.border !== undefined && child.radius !== undefined
            && child.color.a > 0 && child.width > 200 && child.visible);

        compare(filled.length, 0);
    }
}
