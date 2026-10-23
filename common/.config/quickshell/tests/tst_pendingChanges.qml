import QtQuick
import QtTest
import "../config/BarProfileModel.js" as BarProfileModel

// Editing a bar profile: pending changes, Save, Discard and the locked selector.
TestCase {
    name: "PendingChanges"

    function readFixture(fileName) {
        const request = new XMLHttpRequest();
        request.open("GET", Qt.resolvedUrl("fixtures/" + fileName), false);
        request.send(null);
        return JSON.parse(request.responseText);
    }

    function withChanges(state, changes) {
        const updated = Object.assign({}, state);
        for (const key in changes)
            updated[key] = changes[key];
        return updated;
    }

    // The fixture, migrated, as Quickshell starts it: no pending changes.
    function startedState() {
        const migrated = BarProfileModel.migrate(readFixture("appearance.json"),
            readFixture("monitors.json")).appearance;
        return withChanges(migrated, BarProfileModel.discardChanges(migrated));
    }

    function test_aFreshStartHasNoPendingChanges() {
        verify(!BarProfileModel.isModified(startedState()));
    }

    function test_changingABarSettingMarksTheEditedProfileModified() {
        const state = startedState();
        state.barHeight = state.barHeight + 5;

        verify(BarProfileModel.isModified(state));
    }

    function test_theProfileSelectorIsLockedWhileThereArePendingChanges() {
        const state = startedState();
        state.barHeight = state.barHeight + 5;

        compare(BarProfileModel.editProfile(state, "presentation"), null);
    }

    function test_withoutPendingChangesAnotherProfileCanBeEdited() {
        const state = startedState();

        const after = withChanges(state, BarProfileModel.editProfile(state, "presentation"));

        compare(after.editingBarProfile, "presentation");
        compare(after.barHeight, 30);
        verify(!BarProfileModel.isModified(after));
    }

    function test_joiningAnElementIsAPendingChange() {
        const state = startedState();
        const right = state.barElements.right;
        const second = right.filter(element => element.enabled)[1].id;
        state.barElements = BarProfileModel.setElementJoined(state.barElements, second,
            !BarProfileModel.elementJoined(state.barElements, second));

        verify(BarProfileModel.isModified(state));
    }

    function test_changingTheGroupRadiusIsAPendingChange() {
        const state = startedState();
        state.groupRadius = state.groupRadius + 3;

        verify(BarProfileModel.isModified(state));
    }

    function test_applyingADensityPresetIsAPendingChange() {
        const state = startedState();
        const preset = state.barHeight === 38 ? "compact" : "spacious";

        verify(BarProfileModel.isModified(withChanges(state,
            BarProfileModel.densityPresetChanges(preset))));
    }

    function test_savingStoresThePendingChangesAndClearsTheIndicator() {
        const state = startedState();
        state.barHeight = 44;

        const after = withChanges(state, BarProfileModel.saveProfile(state, state.editingBarProfile));

        compare(after.barProfiles[state.editingBarProfile].barHeight, 44);
        verify(!BarProfileModel.isModified(after));
        compare(state.barProfiles[state.editingBarProfile].barHeight, startedState().barHeight);
    }

    function test_discardingRestoresTheSavedValuesAndClearsTheIndicator() {
        const state = startedState();
        const savedHeight = state.barHeight;
        state.barHeight = savedHeight + 9;
        state.groupRadius = state.groupRadius + 3;

        const after = withChanges(state, BarProfileModel.discardChanges(state));

        compare(after.barHeight, savedHeight);
        compare(after.groupRadius, startedState().groupRadius);
        verify(!BarProfileModel.isModified(after));
        compare(after.editingBarProfile, state.editingBarProfile);
    }

    function test_monitorsWithAnotherProfileDoNotSeePendingChanges() {
        const state = startedState();
        verify(state.editingBarProfile !== "work");
        const before = {};
        for (const key of BarProfileModel.profileKeys)
            before[key] = BarProfileModel.profileValue(state, "work", key);

        for (const key of ["barHeight", "barOpacity", "groupRadius", "audioMeterVisible"])
            state[key] = typeof state[key] === "boolean" ? !state[key] : state[key] + 7;

        for (const key of BarProfileModel.profileKeys)
            compare(BarProfileModel.profileValue(state, "work", key), before[key], key);
        compare(BarProfileModel.profileValue(state, state.editingBarProfile, "barHeight"),
            state.barHeight);
    }

    function test_aRestartDropsPendingChanges() {
        // The live settings are persisted as a buffer; starting discards them.
        const state = startedState();
        const savedHeight = state.barHeight;
        state.barHeight = savedHeight + 9;

        const restarted = withChanges(state, BarProfileModel.discardChanges(state));

        compare(restarted.barHeight, savedHeight);
        verify(!BarProfileModel.isModified(restarted));
    }
}
