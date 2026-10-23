import QtQuick
import "../config/BarProfileModel.js" as BarProfileModel
import "../config/SchemaMigrations.js" as SchemaMigrations

// Reads the copies of the real config files in fixtures/ (see README.md).
QtObject {
    function read(fileName) {
        const request = new XMLHttpRequest();
        request.open("GET", Qt.resolvedUrl("fixtures/" + fileName), false);
        request.send(null);
        return JSON.parse(request.responseText);
    }

    // Both fixtures brought to the current schema: { appearance, monitors }.
    function migrated() {
        return SchemaMigrations.migrate(read("appearance.json"), read("monitors.json"));
    }

    // The in-memory bar profile state as Quickshell starts it from the
    // migrated fixtures: the default profile is edited, nothing is pending.
    function startedBarState() {
        const barProfiles = migrated().appearance.barProfiles;
        return {
            barProfiles: barProfiles,
            editingBarProfile: BarProfileModel.initialEditingProfile(barProfiles),
            pendingProfile: null
        };
    }

    // `state` with `changes` (as returned by the model) applied.
    function withChanges(state, changes) {
        const updated = Object.assign({}, state);
        for (const key in changes)
            updated[key] = changes[key];
        return updated;
    }

    // `state` after the panel sets `values` on the edited profile.
    function edited(state, values) {
        return withChanges(state, BarProfileModel.setValues(state, values));
    }
}
