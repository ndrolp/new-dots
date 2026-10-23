import QtQuick
import QtTest
import "../config/BarProfileModel.js" as BarProfileModel
import "../config/SchemaMigrations.js" as SchemaMigrations

// Editing a bar profile: pending changes live in memory, Save, Discard and
// the locked selector.
TestCase {
    name: "PendingChanges"

    Fixtures {
        id: fixtures
    }

    function test_aFreshStartHasNoPendingChanges() {
        const state = fixtures.startedBarState();

        compare(state.editingBarProfile, "minimal");
        verify(!BarProfileModel.isModified(state));
    }

    function test_changingABarSettingMarksTheEditedProfileModified() {
        const state = fixtures.startedBarState();

        const after = fixtures.edited(state, { barHeight: 44 });

        verify(BarProfileModel.isModified(after));
        compare(BarProfileModel.editedProfile(after).barHeight, 44);
    }

    function test_pendingChangesAreNotStoredInTheProfiles() {
        const state = fixtures.startedBarState();

        const changes = BarProfileModel.setValues(state, { barHeight: 44 });

        compare(Object.keys(changes), ["pendingProfile"]);
        compare(state.barProfiles.minimal.barHeight, 34);
    }

    function test_settingTheSavedValueBackLeavesNoPendingChanges() {
        const state = fixtures.edited(fixtures.startedBarState(), { barHeight: 44 });

        const after = fixtures.edited(state, { barHeight: 34 });

        verify(!BarProfileModel.isModified(after));
    }

    function test_theProfileSelectorIsLockedWhileThereArePendingChanges() {
        const state = fixtures.edited(fixtures.startedBarState(), { barHeight: 44 });

        compare(BarProfileModel.editProfile(state, "presentation"), null);
    }

    function test_withoutPendingChangesAnotherProfileCanBeEdited() {
        const state = fixtures.startedBarState();

        const after = fixtures.withChanges(state, BarProfileModel.editProfile(state, "presentation"));

        compare(after.editingBarProfile, "presentation");
        compare(BarProfileModel.editedProfile(after).barHeight, 30);
        verify(!BarProfileModel.isModified(after));
    }

    function test_editingAnUnknownProfileChangesNothing() {
        compare(BarProfileModel.editProfile(fixtures.startedBarState(), "missing"), null);
    }

    function test_joiningAnElementIsAPendingChange() {
        const state = fixtures.startedBarState();
        const barElements = BarProfileModel.editedProfile(state).barElements;
        const second = barElements.right.filter(element => element.enabled)[1].id;

        const after = fixtures.edited(state, { barElements: BarProfileModel.setElementJoined(
            barElements, second, !BarProfileModel.elementJoined(barElements, second)) });

        verify(BarProfileModel.isModified(after));
    }

    function test_applyingADensityPresetIsAPendingChange() {
        const state = fixtures.startedBarState();

        verify(BarProfileModel.isModified(fixtures.edited(state,
            BarProfileModel.densityPresetChanges("spacious"))));
    }

    function test_savingStoresThePendingChangesAndClearsTheIndicator() {
        const state = fixtures.edited(fixtures.startedBarState(), { barHeight: 44 });

        const after = fixtures.withChanges(state, BarProfileModel.saveProfile(state));

        compare(after.barProfiles.minimal.barHeight, 44);
        compare(after.pendingProfile, null);
        verify(!BarProfileModel.isModified(after));
        compare(state.barProfiles.minimal.barHeight, 34);
    }

    function test_discardingRestoresTheSavedValuesAndClearsTheIndicator() {
        const state = fixtures.edited(fixtures.startedBarState(), { barHeight: 39, groupRadius: 3 });

        const after = fixtures.withChanges(state, BarProfileModel.discardChanges(state));

        compare(BarProfileModel.editedProfile(after).barHeight, 34);
        verify(!BarProfileModel.isModified(after));
        compare(after.editingBarProfile, "minimal");
    }

    function test_monitorsWithAnotherProfileDoNotSeePendingChanges() {
        const state = fixtures.startedBarState();
        const before = BarProfileModel.profileValue(state, "work", "barHeight");

        const after = fixtures.edited(state, { barHeight: 44 });

        compare(BarProfileModel.profileValue(after, "work", "barHeight"), before);
        compare(BarProfileModel.profileValue(after, "minimal", "barHeight"), 44);
    }

    function test_savedProfilesChangingOnDiskKeepThePendingChanges() {
        // Another Quickshell instance saving its profiles must not wipe edits.
        const state = fixtures.edited(fixtures.startedBarState(), { barHeight: 44 });
        const reloaded = JSON.parse(JSON.stringify(state.barProfiles));
        reloaded.work.barHeight = 40;

        const after = fixtures.withChanges(state, { barProfiles: reloaded });

        compare(BarProfileModel.editedProfile(after).barHeight, 44);
        compare(BarProfileModel.profileValue(after, "work", "barHeight"), 40);
    }

    function test_theMigratedFileHoldsOnlyProfilesAndGlobalSettings() {
        const appearance = fixtures.migrated().appearance;

        compare(Object.keys(appearance).sort(),
            ["barProfiles", "doNotDisturb", "notificationPopupLocation", "schemaVersion"]);
    }

    function test_theOldActiveProfilesTopLevelValuesWinOverItsSavedCopy() {
        // Story 59: the top-level values were what the active profile showed.
        const appearance = fixtures.read("appearance.json");
        appearance.barHeight = 99;
        appearance.textSize = 20;

        const migrated = SchemaMigrations.migrate(appearance,
            fixtures.read("monitors.json")).appearance;

        compare(migrated.barProfiles.minimal.barHeight, 99);
        compare(migrated.barProfiles.minimal.textSize, 20);
        compare(migrated.barProfiles.work.barHeight, 30);
    }

    function test_settingsAnOldProfileDidNotSaveKeepWhatItsMonitorsDrew() {
        const fixture = fixtures.read("appearance.json");
        verify(fixture.barProfiles.work.barOpacity === undefined);

        const migrated = fixtures.migrated().appearance;

        compare(migrated.barProfiles.work.barOpacity, fixture.barOpacity);
    }
}
