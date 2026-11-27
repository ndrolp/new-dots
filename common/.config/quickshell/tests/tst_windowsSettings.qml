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
    visible: true
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

    function test_withoutASavedFileTheGapsAreTodaysDefaults() {
        compare(saved(null), { gaps_in: 5, gaps_out: 10 });
        compare(saved(undefined), { gaps_in: 5, gaps_out: 10 });
    }

    function test_aBadGapFallsBackAloneAndTheOtherIsKept() {
        compare(saved('{ "gaps_in": 31, "gaps_out": 20 }'), { gaps_in: 5, gaps_out: 20 });
        compare(saved('{ "gaps_in": 3, "gaps_out": "wide" }'), { gaps_in: 3, gaps_out: 10 });
        compare(saved('{ "gaps_in": 2.5 }'), { gaps_in: 5, gaps_out: 10 });
    }

    function test_aFileThatIsntAJsonObjectGivesTheDefaults() {
        compare(saved('{ "gaps_in": 3,'), { gaps_in: 5, gaps_out: 10 });
        compare(saved("[3, 20]"), { gaps_in: 5, gaps_out: 10 });
    }

    // A change writes the whole file: every setting, the changed one with
    // its new value, kept in range and whole.
    function test_aChangeWritesTheFileWithEverySetting() {
        const values = WindowAppearance.withValue(saved(null), "gaps_out", 24);

        compare(JSON.parse(WindowAppearance.fileText(values)), { gaps_in: 5, gaps_out: 24 });
        verify(WindowAppearance.fileText(values).endsWith("\n"), "it ends in a newline");
    }

    function test_aChangeIsKeptInRangeAndWhole() {
        const values = saved('{ "gaps_in": 8, "gaps_out": 20 }');

        compare(WindowAppearance.withValue(values, "gaps_in", 99), { gaps_in: 30, gaps_out: 20 });
        compare(WindowAppearance.withValue(values, "gaps_out", -4), { gaps_in: 8, gaps_out: 0 });
        compare(WindowAppearance.withValue(values, "gaps_in", 6.6), { gaps_in: 7, gaps_out: 20 });
    }

    // Hyprland re-runs only the window-appearance module, never its whole config.
    function test_applyingAsksHyprlandToRunOnlyTheWindowAppearanceModule() {
        compare(WindowAppearance.applyCommand,
            ["hyprctl", "eval", 'require("modules.appearence.windows").apply()']);
    }

    // hyprctl fails outside Hyprland, and says "error" when the module's
    // Lua fails; either way Hyprland didn't take the change.
    function test_anApplyFailsWhenHyprctlFailsOrReportsAnError() {
        verify(!WindowAppearance.applyFailed(0, ""), "a quiet success");
        verify(!WindowAppearance.applyFailed(0, "ok\n"), "an ok");
        verify(WindowAppearance.applyFailed(1, "HYPRLAND_INSTANCE_SIGNATURE not set! (is hyprland running?)\n"),
            "outside Hyprland");
        verify(WindowAppearance.applyFailed(0, "error: [string]:1: attempt to index a nil value\n"), "a Lua error");
        verify(WindowAppearance.applyFailed(127, ""), "no hyprctl");
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
                property bool applyFailed: false
                property int resets: 0

                function reset() {
                    resets++;
                    values = WindowAppearance.defaults();
                }

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

    function button(item, label) {
        return all(item, child => child.label === label && child.activated !== undefined)[0];
    }

    function failureHint(item) {
        return all(item, child => child.text === "Couldn't apply to Hyprland; it will apply on next start.")[0];
    }

    // Reset needs no confirmation: one press and every setting is back to
    // its default.
    function test_resetPutsEverySettingBackStraightAway() {
        const built = make();

        button(built.section, "Reset to defaults").activated();

        compare(built.service.resets, 1);
        compare(number(built.section, "Inner gaps").value, 5);
        compare(number(built.section, "Outer gaps").value, 10);
    }

    // Shown in the section, not as a toast, while Hyprland couldn't take the
    // last change; it goes once an apply works.
    function test_aFailedApplyShowsAHintUntilTheNextOneWorks() {
        const built = make();
        const hint = failureHint(built.section);

        verify(hint, "the section has the hint");
        verify(!hint.visible, "hidden while applies work");
        built.service.applyFailed = true;
        verify(hint.visible, "shown after a failed apply");
        built.service.applyFailed = false;
        verify(!hint.visible, "cleared by the next apply that works");
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
