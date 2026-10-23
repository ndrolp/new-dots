import QtQuick
import QtTest
import "../config/BarProfileModel.js" as BarProfileModel
import "../config/SchemaMigrations.js" as SchemaMigrations

// Duplicating and deleting bar profiles from the panel.
TestCase {
    name: "DuplicateDelete"

    Fixtures {
        id: fixtures
    }

    function withChanges(state, changes) {
        const updated = Object.assign({}, state);
        for (const key in changes)
            updated[key] = changes[key];
        return updated;
    }

    // The fixtures, migrated, as Quickshell starts them: no pending changes.
    function started() {
        const migrated = SchemaMigrations.migrate(fixtures.read("appearance.json"),
            fixtures.read("monitors.json"));
        const appearance = withChanges(migrated.appearance,
            BarProfileModel.discardChanges(migrated.appearance));
        return { appearance: appearance, displaySettings: migrated.monitors.displaySettings };
    }

    function test_theSuggestedNameIsTheFirstFreeNumberedName() {
        const state = started().appearance;
        compare(BarProfileModel.suggestedDuplicateName(state, "work"), "work 2");

        state.barProfiles = Object.assign({}, state.barProfiles,
            { "work 2": {}, "work 3": {} });
        compare(BarProfileModel.suggestedDuplicateName(state, "work"), "work 4");
    }

    function test_duplicatingCopiesTheProfileAndEditsTheCopy() {
        const state = started().appearance;

        const after = withChanges(state,
            BarProfileModel.duplicateProfile(state, "presentation", "talks"));

        compare(after.editingBarProfile, "talks");
        compare(after.barProfiles.talks.barHeight, 30);
        compare(after.barHeight, 30);
        compare(after.barProfiles.presentation, state.barProfiles.presentation);
        verify(!BarProfileModel.isModified(after));
    }

    function test_anEmptyOrExistingNameIsRejected() {
        const state = started().appearance;

        compare(BarProfileModel.duplicateNameError(state, ""), "empty");
        compare(BarProfileModel.duplicateNameError(state, "   "), "empty");
        compare(BarProfileModel.duplicateNameError(state, "work"), "exists");
        compare(BarProfileModel.duplicateNameError(state, "talks"), "");
        compare(BarProfileModel.duplicateProfile(state, "work", ""), null);
        compare(BarProfileModel.duplicateProfile(state, "work", "media"), null);
    }

    function test_theNameIsTrimmed() {
        const state = started().appearance;

        const after = withChanges(state,
            BarProfileModel.duplicateProfile(state, "work", "  talks "));

        compare(after.editingBarProfile, "talks");
        compare(BarProfileModel.duplicateNameError(after, " talks"), "exists");
    }

    function test_duplicatingIsUnavailableWithPendingChanges() {
        const state = started().appearance;
        state.barHeight = state.barHeight + 5;

        verify(!BarProfileModel.canDuplicateOrDelete(state));
        compare(BarProfileModel.duplicateProfile(state, state.editingBarProfile, "talks"), null);
    }

    function test_deletingAnUnassignedProfileRemovesIt() {
        const fixture = started();
        compare(BarProfileModel.monitorsUsingProfile(fixture.displaySettings, "work"), []);

        const after = withChanges(fixture.appearance, BarProfileModel.deleteProfile(
            fixture.appearance, fixture.displaySettings, "work"));

        compare(Object.keys(after.barProfiles).sort(), ["media", "minimal", "presentation"]);
        compare(after.editingBarProfile, fixture.appearance.editingBarProfile);
    }

    function test_deletingTheEditedProfileEditsTheDefaultOne() {
        const fixture = started();
        const editing = withChanges(fixture.appearance,
            BarProfileModel.editProfile(fixture.appearance, "presentation"));

        const after = withChanges(editing,
            BarProfileModel.deleteProfile(editing, fixture.displaySettings, "presentation"));

        verify(after.barProfiles.presentation === undefined);
        compare(after.editingBarProfile, "minimal");
        compare(after.barHeight, fixture.appearance.barProfiles.minimal.barHeight);
        verify(!BarProfileModel.isModified(after));
    }

    function test_deletingAnAssignedProfileIsRejectedNamingItsMonitors() {
        const fixture = started();
        const monitor = "Philips Consumer Electronics Company PHL 243V7 0x00009A4C";
        fixture.displaySettings[monitor].barProfile = "work";

        compare(BarProfileModel.monitorsUsingProfile(fixture.displaySettings, "work"), [monitor]);
        compare(BarProfileModel.deleteRejection(fixture.appearance, fixture.displaySettings,
            "work"), "assigned");
        compare(BarProfileModel.deleteProfile(fixture.appearance, fixture.displaySettings,
            "work"), null);
    }

    function test_aProfileOnlyTheDefaultEntryUsesIsAssigned() {
        const fixture = started();

        compare(BarProfileModel.monitorsUsingProfile({ "default": { barProfile: "work" } },
            "work"), ["default"]);
        compare(BarProfileModel.deleteProfile(fixture.appearance,
            { "default": { barProfile: "work" } }, "work"), null);
    }

    function test_deletingTheLastProfileIsRejected() {
        const state = started().appearance;
        state.barProfiles = { "work": state.barProfiles.work };

        compare(BarProfileModel.deleteRejection(state, {}, "work"), "last");
        compare(BarProfileModel.deleteProfile(state, {}, "work"), null);
    }

    function test_deletingIsUnavailableWithPendingChanges() {
        const fixture = started();
        fixture.appearance.barHeight = fixture.appearance.barHeight + 5;

        compare(BarProfileModel.deleteRejection(fixture.appearance, fixture.displaySettings,
            "work"), "pending");
        compare(BarProfileModel.deleteProfile(fixture.appearance, fixture.displaySettings,
            "work"), null);
    }

    function test_anUnassignedProfileCanBeDeleted() {
        const fixture = started();

        compare(BarProfileModel.deleteRejection(fixture.appearance, fixture.displaySettings,
            "work"), "");
    }
}
