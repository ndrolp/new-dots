import QtQuick
import QtTest
import "../components/panels" as Panels
import "../config" as Config

// The Bar section's bar profile selector, built from the settings parts: the
// bar profiles as a segmented choice, quiet text buttons for Duplicate,
// Delete, Save and Discard.
TestCase {
    name: "BarProfileSelector"
    width: 800
    height: 600
    when: windowShown
    // Shown, so that `visible` tells which buttons and messages are shown.
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

    function button(item, label) {
        return all(item, child => child.label === label && child.activated !== undefined
            && child.visible)[0] || null;
    }

    function profileChoice(item) {
        return all(item, child => child.options !== undefined && child.chosen !== undefined)[0];
    }

    function textOf(item, text) {
        return all(item, child => child.text === text && child.font !== undefined
            && !(child instanceof TextInput) && child.visible)[0] || null;
    }

    // A fake appearance stands in for the shell's and records what is asked.
    Component {
        id: page

        Item {
            property alias appearance: appearance
            property alias selector: selector

            width: 700

            QtObject {
                id: appearance

                property int radius: 12
                property int textSize: 13
                property var barProfiles: ({ "work": {}, "media": {}, "minimal": {} })
                property string editingBarProfile: "work"
                property bool barProfileModified: false
                property string rejection: ""
                property var calls: []

                function record(call) {
                    calls = calls.concat([call]);
                }

                function duplicateNameError(name) {
                    return name.trim() === "" ? "empty" : barProfiles[name.trim()] ? "exists" : "";
                }

                function deleteBarProfileRejection(profile, displaySettings) {
                    return rejection;
                }

                function suggestedDuplicateName() {
                    return "work 2";
                }

                function duplicateBarProfile(name) {
                    record(["duplicate", name]);
                }

                function deleteBarProfile(profile) {
                    record(["delete", profile]);
                }

                function editBarProfile(profile) {
                    record(["edit", profile]);
                }

                function saveBarProfile() {
                    record(["save"]);
                }

                function discardBarProfileChanges() {
                    record(["discard"]);
                }
            }

            Panels.BarProfileSelector {
                id: selector

                appearance: appearance
            }
        }
    }

    function make() {
        const built = createTemporaryObject(page, this);
        return { appearance: built.appearance, item: built.selector };
    }

    function test_theProfilesAreAChoiceMarkingTheEditedOne() {
        const built = make();
        const choice = profileChoice(built.item);

        compare(choice.options.map(option => option.label), ["Media", "Minimal", "Work"]);
        compare(choice.value, "work");
        compare(textOf(choice, "Work").color, theme.accent);
    }

    function test_choosingAProfileEditsIt() {
        const built = make();

        profileChoice(built.item).chosen("media");

        compare(built.appearance.calls, [["edit", "media"]]);
    }

    function test_withPendingChangesTheChoiceIsLockedAndOnlySaveAndDiscardShow() {
        const built = make();
        built.appearance.barProfileModified = true;

        verify(!profileChoice(built.item).enabled);
        verify(!button(built.item, "Duplicate"));
        verify(!button(built.item, "Delete"));

        button(built.item, "Discard").activated();
        button(built.item, "Save").activated();
        compare(built.appearance.calls, [["discard"], ["save"]]);
    }

    function test_saveIsHiddenWithoutPendingChanges() {
        const built = make();

        verify(!button(built.item, "Save"));
        verify(!button(built.item, "Discard"));
        verify(profileChoice(built.item).enabled);
    }

    function test_duplicatingAsksForANameAndCreatesTheCopy() {
        const built = make();

        button(built.item, "Duplicate").activated();
        const field = all(built.item, child => child instanceof TextInput && child.visible)[0];
        compare(field.text, "work 2");

        button(built.item, "Create").activated();
        compare(built.appearance.calls, [["duplicate", "work 2"]]);
    }

    function test_duplicatingUnderAnExistingNameIsRefused() {
        const built = make();

        button(built.item, "Duplicate").activated();
        const field = all(built.item, child => child instanceof TextInput && child.visible)[0];
        field.text = "media";

        verify(textOf(built.item, "A profile with that name already exists."));
        button(built.item, "Create").activated();
        compare(built.appearance.calls, []);
    }

    function test_deletingAsksToConfirm() {
        const built = make();

        button(built.item, "Delete").activated();
        verify(textOf(built.item, "Delete \"Work\"? This can't be undone."));

        button(built.item, "Delete permanently").activated();
        compare(built.appearance.calls, [["delete", "work"]]);
    }

    function test_aProfileThatCannotBeDeletedSaysWhyWithoutAConfirmButton() {
        const built = make();
        built.appearance.rejection = "last";

        button(built.item, "Delete").activated();

        verify(textOf(built.item, "Can't delete the last bar profile."));
        verify(!button(built.item, "Delete permanently"));
    }

    function test_nothingInTheSelectorIsBoldOrWrittenInCapitals() {
        const built = make();
        built.appearance.barProfileModified = true;
        const loud = all(built.item, child => child.font !== undefined
            && (child.font.bold || (child.text !== undefined && child.text.length > 1
                    && child.text === child.text.toUpperCase() && /[A-Z]/.test(child.text))));

        compare(loud.map(child => child.text), []);
    }

    function test_nothingIsAFilledCard() {
        const built = make();
        const filled = all(built.item, child => child.border !== undefined && child.radius !== undefined
            && child.color.a > 0 && child.width > 200 && child.visible);

        compare(filled.length, 0);
    }
}
