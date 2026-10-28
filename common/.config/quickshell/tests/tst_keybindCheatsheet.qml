import QtQuick
import QtTest
import "../components/panels/KeybindCheatsheet.js" as KeybindCheatsheet

// The keybind cheatsheet lists every binding Hyprland reports in
// `hyprctl binds -j` (fixtures/hyprctl-binds.json is a slice of the real
// output), grouped by modifier and searchable by key or description.
TestCase {
    name: "KeybindCheatsheet"

    Fixtures {
        id: fixtures
    }

    function test_aModifierMaskIsShownAsItsKeyNames() {
        compare(KeybindCheatsheet.modifierLabel(65), "SUPER + SHIFT");
        compare(KeybindCheatsheet.modifierLabel(12), "CTRL + ALT");
        compare(KeybindCheatsheet.modifierLabel(8), "ALT");
        compare(KeybindCheatsheet.modifierLabel(0), "");
    }

    function groupNames(groups) {
        return groups.map(group => group.modifiers);
    }

    // Groups follow the modifiers' order; keys pressed alone come last.
    function test_bindingsAreGroupedByModifier() {
        const groups = KeybindCheatsheet.groups(fixtures.read("hyprctl-binds.json"));

        compare(groupNames(groups), [
            "ALT", "ALT + SHIFT", "CTRL + ALT", "SUPER", "SUPER + SHIFT", "No modifier"
        ]);
    }

    // Within a group, bindings keep the order they are configured in.
    function test_eachEntryShowsTheWholeComboAndItsDescription() {
        const alt = KeybindCheatsheet.groups(fixtures.read("hyprctl-binds.json"))[0];

        compare(alt.entries.map(entry => entry.keys + " " + entry.description), [
            "ALT + 1 Go to workspace 1",
            "ALT + RETURN Open terminal",
            "ALT + F Toggle unified search",
            "ALT + Left click Drag window"
        ]);
    }

    // A binding registered twice is listed once.
    function test_aRepeatedBindingIsListedOnce() {
        const altShift = KeybindCheatsheet.groups(fixtures.read("hyprctl-binds.json"))[1];

        compare(altShift.entries.map(entry => entry.keys), ["ALT + SHIFT + 1", "ALT + SHIFT + S"]);
    }

    function test_aKeyWithoutModifiersIsShownAlone() {
        const groups = KeybindCheatsheet.groups(fixtures.read("hyprctl-binds.json"));

        compare(groups[groups.length - 1].entries[0].keys, "XF86AudioRaiseVolume");
    }

    // The panel hands over hyprctl's output as text; output that isn't a
    // binding list (hyprctl failed, Hyprland isn't running) shows nothing.
    function test_theCheatsheetReadsHyprctlOutputAsText() {
        const text = JSON.stringify(fixtures.read("hyprctl-binds.json"));

        compare(groupNames(KeybindCheatsheet.fromOutput(text)).length, 6);
        compare(KeybindCheatsheet.fromOutput(""), []);
        compare(KeybindCheatsheet.fromOutput("ok"), []);
        compare(KeybindCheatsheet.fromOutput("{}"), []);
    }

    function filtered(query) {
        return KeybindCheatsheet.filter(
            KeybindCheatsheet.groups(fixtures.read("hyprctl-binds.json")), query);
    }

    function test_typingFiltersByDescription() {
        compare(filtered("Workspace").map(group => group.entries.map(entry => entry.keys)),
            [["ALT + 1"], ["ALT + SHIFT + 1"]]);
    }

    // Every word must match the combo or the description, so typing the
    // modifiers narrows the list to that combination.
    function test_typingFiltersByKey() {
        compare(filtered("super shift").map(group => group.entries.map(entry => entry.keys)),
            [["SUPER + SHIFT + S"]]);
        compare(filtered("ctrl + alt").map(group => group.entries.map(entry => entry.description)),
            [["Bar profile: minimal"]]);
    }

    function test_anEmptyQueryKeepsEveryBinding() {
        compare(groupNames(filtered("  ")).length, 6);
    }

    function test_nothingMatchingLeavesNoGroups() {
        compare(filtered("no such binding"), []);
    }
}
