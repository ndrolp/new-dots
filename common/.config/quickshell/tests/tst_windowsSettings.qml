import QtQuick
import QtTest
import "../components/panels" as Panels
import "../config/Motion.js" as Motion
import "../services/WindowAppearance.js" as WindowAppearance

// The Windows section: how Hyprland draws windows, saved to one
// machine-local file Hyprland reads (hypr/modules/appearence/windows.lua).
// Each change is written to that file straight away; nothing waits for a save.
TestCase {
    name: "WindowsSettings"
    width: 800
    height: 600
    when: windowShown

    function all(item, predicate, found) {
        found = found || [];
        if (predicate(item))
            found.push(item);
        for (let i = 0; i < item.children.length; i++)
            all(item.children[i], predicate, found);
        return found;
    }

    function number(item, label) {
        return all(item, child => child.label === label && child.slider !== undefined)[0];
    }

    // The values the saved file gives, with an empty file standing for none.
    function saved(text) {
        return WindowAppearance.valuesFrom(text);
    }

    function gaps(values) {
        return { gaps_in: values.gaps_in, gaps_out: values.gaps_out };
    }

    function bordersAndRounding(values) {
        return { border_size: values.border_size, rounding: values.rounding };
    }

    function test_withoutASavedFileTheBorderSizeAndRoundingAreTodaysDefaults() {
        compare(bordersAndRounding(saved(null)), { border_size: 2, rounding: 5 });
    }

    function test_aBadBorderSizeOrRoundingFallsBackAlone() {
        compare(bordersAndRounding(saved('{ "border_size": 0, "rounding": 24 }')), { border_size: 0, rounding: 24 });
        compare(bordersAndRounding(saved('{ "border_size": 7, "rounding": 12 }')), { border_size: 2, rounding: 12 });
        compare(bordersAndRounding(saved('{ "border_size": 3, "rounding": 25 }')), { border_size: 3, rounding: 5 });
        compare(bordersAndRounding(saved('{ "border_size": 1.5, "rounding": -1 }')), { border_size: 2, rounding: 5 });
    }

    function test_theBorderSizeAndRoundingAreKeptInRangeAndWhole() {
        const values = saved(null);

        compare(WindowAppearance.withValue(values, "border_size", 9).border_size, 6);
        compare(WindowAppearance.withValue(values, "rounding", 30).rounding, 24);
        compare(WindowAppearance.withValue(values, "rounding", 3.4).rounding, 3);
    }

    function test_withoutASavedFileTheGapsAreTodaysDefaults() {
        compare(gaps(saved(null)), { gaps_in: 5, gaps_out: 10 });
        compare(gaps(saved(undefined)), { gaps_in: 5, gaps_out: 10 });
    }

    function test_aBadGapFallsBackAloneAndTheOtherIsKept() {
        compare(gaps(saved('{ "gaps_in": 31, "gaps_out": 20 }')), { gaps_in: 5, gaps_out: 20 });
        compare(gaps(saved('{ "gaps_in": 3, "gaps_out": "wide" }')), { gaps_in: 3, gaps_out: 10 });
        compare(gaps(saved('{ "gaps_in": 2.5 }')), { gaps_in: 5, gaps_out: 10 });
    }

    function test_aFileThatIsntAJsonObjectGivesTheDefaults() {
        compare(gaps(saved('{ "gaps_in": 3,')), { gaps_in: 5, gaps_out: 10 });
        compare(gaps(saved("[3, 20]")), { gaps_in: 5, gaps_out: 10 });
    }

    // A change writes the whole file: every setting, the changed one with
    // its new value, kept in range and whole.
    function test_aChangeWritesTheFileWithEverySetting() {
        const values = WindowAppearance.withValue(saved(null), "gaps_out", 24);

        compare(gaps(JSON.parse(WindowAppearance.fileText(values))), { gaps_in: 5, gaps_out: 24 });
        compare(Object.keys(JSON.parse(WindowAppearance.fileText(values))).sort(),
            Object.keys(WindowAppearance.settings).sort());
        verify(WindowAppearance.fileText(values).endsWith("\n"), "it ends in a newline");
    }

    function test_aChangeIsKeptInRangeAndWhole() {
        const values = saved('{ "gaps_in": 8, "gaps_out": 20 }');

        compare(gaps(WindowAppearance.withValue(values, "gaps_in", 99)), { gaps_in: 30, gaps_out: 20 });
        compare(gaps(WindowAppearance.withValue(values, "gaps_out", -4)), { gaps_in: 8, gaps_out: 0 });
        compare(gaps(WindowAppearance.withValue(values, "gaps_in", 6.6)), { gaps_in: 7, gaps_out: 20 });
    }

    // Hyprland re-runs only the window-appearance module, never its whole config.
    function test_applyingAsksHyprlandToRunOnlyTheWindowAppearanceModule() {
        compare(WindowAppearance.applyCommand,
            ["hyprctl", "eval", 'require("modules.appearence.windows").apply()']);
    }

    // Where the settings panel shows a section, with a fake service that
    // keeps what it is asked to set.
    Component {
        id: sectionArea

        Item {
            property alias service: service
            property alias section: section

            width: 700

            QtObject {
                id: appearance

                property int radius: 12
                property int textSize: 13
                readonly property var motion: Motion.motion(false)
            }

            QtObject {
                id: service

                property var values: WindowAppearance.valuesFrom('{ "gaps_in": 8 }')
                property var asked: []

                function set(key, value) {
                    asked = asked.concat([[key, value]]);
                    values = WindowAppearance.withValue(values, key, value);
                }
            }

            Panels.WindowsSettings {
                id: section

                appearance: appearance
                windowAppearance: service
            }
        }
    }

    function make() {
        return createTemporaryObject(sectionArea, this);
    }

    function test_theGapsShowTheSavedValuesInTheirRanges() {
        const built = make();
        const inner = number(built.section, "Inner gaps");
        const outer = number(built.section, "Outer gaps");

        compare([inner.from, inner.to, inner.value], [0, 30, 8]);
        compare([outer.from, outer.to, outer.value], [0, 60, 10]);
    }

    function test_movingAGapSetsIt() {
        const built = make();
        const inner = number(built.section, "Inner gaps");
        const outer = number(built.section, "Outer gaps");

        inner.edited(12);
        outer.edited(40);

        compare(built.service.asked, [["gaps_in", 12], ["gaps_out", 40]]);
        compare(inner.value, 12);
        compare(outer.value, 40);
    }

    function test_theBorderSizeAndCornerRadiusShowTheirValuesInTheirRanges() {
        const built = make();
        const border = number(built.section, "Border size");
        const radius = number(built.section, "Corner radius");

        compare([border.from, border.to, border.value], [0, 6, 2]);
        compare([radius.from, radius.to, radius.value], [0, 24, 5]);
    }

    function test_movingTheBorderSizeOrCornerRadiusSetsIt() {
        const built = make();
        const border = number(built.section, "Border size");
        const radius = number(built.section, "Corner radius");

        border.edited(0);
        radius.edited(16);

        compare(built.service.asked, [["border_size", 0], ["rounding", 16]]);
        compare(border.value, 0);
        compare(radius.value, 16);
    }

    // Before the service is there (or in a panel without one) the section
    // shows the defaults.
    function test_withoutTheServiceTheGapsShowTheDefaults() {
        const section = createTemporaryObject(sectionWithoutService, this);

        compare(number(section, "Inner gaps").value, 5);
        compare(number(section, "Outer gaps").value, 10);
    }

    Component {
        id: sectionWithoutService

        Panels.WindowsSettings {
            width: 700
            appearance: QtObject {
                property int radius: 12
                property int textSize: 13
                readonly property var motion: Motion.motion(false)
            }
        }
    }
}
