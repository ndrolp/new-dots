import QtQuick
import QtTest
import "../config/BarProfileModel.js" as BarProfileModel
import "../config/SchemaMigrations.js" as SchemaMigrations

// Duplicating, renaming and deleting bar profiles from the panel.
TestCase {
    name: "DuplicateDelete"

    Fixtures {
        id: fixtures
    }

    // The fixtures, migrated, as Quickshell starts them: no pending changes.
    function started() {
        return {
            appearance: fixtures.startedBarState(),
            displaySettings: fixtures.migrated().monitors.displaySettings
        };
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

        const after = fixtures.withChanges(state,
            BarProfileModel.duplicateProfile(state, "presentation", "talks"));

        compare(after.editingBarProfile, "talks");
        compare(after.barProfiles.talks.barHeight, 30);
        compare(BarProfileModel.editedProfile(after).barHeight, 30);
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

        const after = fixtures.withChanges(state,
            BarProfileModel.duplicateProfile(state, "work", "  talks "));

        compare(after.editingBarProfile, "talks");
        compare(BarProfileModel.duplicateNameError(after, " talks"), "exists");
    }

    // Renaming moves the profile, settings and all, to the new name and keeps
    // editing it; the old name is gone.
    function test_renamingMovesTheProfileToItsNewNameAndKeepsEditingIt() {
        const state = started().appearance;
        const editing = BarProfileModel.editProfile(state, "presentation");
        const before = fixtures.withChanges(state, editing);

        const after = fixtures.withChanges(before,
            BarProfileModel.renameProfile(before, "presentation", "  talks "));

        compare(after.editingBarProfile, "talks");
        compare(after.barProfiles.talks, before.barProfiles.presentation);
        compare(after.barProfiles.presentation, undefined);
        verify(!BarProfileModel.isModified(after));
    }

    // Renaming a profile other than the edited one leaves the editing alone.
    function test_renamingAnotherProfileKeepsTheEditedOne() {
        const state = started().appearance;

        const after = fixtures.withChanges(state, BarProfileModel.renameProfile(state, "media", "music"));

        compare(after.editingBarProfile, state.editingBarProfile);
        compare(after.barProfiles.music, state.barProfiles.media);
    }

    // A new name must be given, unused, and different from the current one.
    function test_aRenameToAnEmptyTakenOrSameNameIsRefused() {
        const state = started().appearance;

        compare(BarProfileModel.renameNameError(state, "work", " "), "empty");
        compare(BarProfileModel.renameNameError(state, "work", "media"), "exists");
        compare(BarProfileModel.renameNameError(state, "work", " work "), "same");
        compare(BarProfileModel.renameNameError(state, "work", "office"), "");
        compare(BarProfileModel.renameProfile(state, "work", "media"), null);
        compare(BarProfileModel.renameProfile(state, "work", "work"), null);
        compare(BarProfileModel.renameProfile(state, "nowhere", "office"), null);
    }

    function test_renamingIsUnavailableWithPendingChanges() {
        const state = fixtures.edited(started().appearance, { barHeight: 44 });

        compare(BarProfileModel.renameProfile(state, state.editingBarProfile, "office"), null);
    }

    function test_duplicatingIsUnavailableWithPendingChanges() {
        const state = fixtures.edited(started().appearance, { barHeight: 44 });

        verify(!BarProfileModel.canDuplicateOrDelete(state));
        compare(BarProfileModel.duplicateProfile(state, state.editingBarProfile, "talks"), null);
    }

    function test_deletingAnUnassignedProfileRemovesIt() {
        const fixture = started();
        compare(BarProfileModel.monitorsUsingProfile(fixture.displaySettings, "work"), []);

        const after = fixtures.withChanges(fixture.appearance, BarProfileModel.deleteProfile(
            fixture.appearance, fixture.displaySettings, "work"));

        compare(Object.keys(after.barProfiles).sort(), ["media", "minimal", "presentation"]);
        compare(after.editingBarProfile, fixture.appearance.editingBarProfile);
    }

    function test_deletingTheEditedProfileEditsTheFirstRemainingOne() {
        const fixture = started();
        const editing = fixtures.withChanges(fixture.appearance,
            BarProfileModel.editProfile(fixture.appearance, "presentation"));

        const changes = BarProfileModel.deleteProfile(editing, fixture.displaySettings,
            "presentation");
        const after = fixtures.withChanges(editing, changes);

        verify(after.barProfiles.presentation === undefined);
        // Returned explicitly, so the panel shows the profile it now edits.
        compare(changes.editingBarProfile, "media");
        compare(BarProfileModel.editedProfile(after).barHeight,
            fixture.appearance.barProfiles.media.barHeight);
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

    function test_deletingTheLastProfileIsRejected() {
        const state = started().appearance;
        state.barProfiles = { "work": state.barProfiles.work };

        compare(BarProfileModel.deleteRejection(state, {}, "work"), "last");
        compare(BarProfileModel.deleteProfile(state, {}, "work"), null);
    }

    function test_deletingIsUnavailableWithPendingChanges() {
        const fixture = started();
        fixture.appearance = fixtures.edited(fixture.appearance, { barHeight: 44 });

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
