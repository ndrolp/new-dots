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
}
