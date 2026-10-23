import QtQuick
import QtTest
import "../config/BarProfileModel.js" as BarProfileModel

// Density presets are a shortcut that fills in the bar sizes of the edited
// profile; the preset itself is never stored.
TestCase {
    name: "DensityPresets"

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

    function startedState() {
        const migrated = BarProfileModel.migrate(readFixture("appearance.json"),
            readFixture("monitors.json")).appearance;
        return withChanges(migrated, BarProfileModel.discardChanges(migrated));
    }

    function test_applyingAPresetFillsTheSizesAndMarksTheProfileModified() {
        const state = startedState();
        const preset = state.barHeight === 38 ? "compact" : "spacious";

        const after = withChanges(state, BarProfileModel.densityPresetChanges(preset));

        compare(after.barHeight, preset === "compact" ? 30 : 38);
        verify(BarProfileModel.isModified(after));
    }

    function test_savingAfterAPresetLeavesNoTraceOfThePreset() {
        const state = startedState();
        const applied = withChanges(state, BarProfileModel.densityPresetChanges("compact"));

        const saved = withChanges(applied,
            BarProfileModel.saveProfile(applied, applied.editingBarProfile));

        const profile = saved.barProfiles[saved.editingBarProfile];
        compare(profile.barHeight, 30);
        compare(profile.densityPreset, undefined);
        compare(saved.densityPreset, undefined);
    }

    function test_discardingAfterAPresetRestoresTheSavedSizes() {
        const state = startedState();
        const applied = withChanges(state, BarProfileModel.densityPresetChanges("spacious"));

        const discarded = withChanges(applied, BarProfileModel.discardChanges(applied));

        compare(discarded.barHeight, state.barHeight);
        verify(!BarProfileModel.isModified(discarded));
    }

    function test_theMatchingPresetIsDerivedFromTheSizes() {
        const state = withChanges(startedState(), BarProfileModel.densityPresetChanges("spacious"));
        compare(BarProfileModel.matchingDensityPreset(state), "spacious");

        state.barHeight = 99;
        compare(BarProfileModel.matchingDensityPreset(state), "");
    }

    function test_migrationRemovesTheStoredPresetFromEveryProfile() {
        const fixture = readFixture("appearance.json");
        verify(fixture.densityPreset !== undefined);

        const migrated = BarProfileModel.migrate(fixture, readFixture("monitors.json")).appearance;

        compare(migrated.densityPreset, undefined);
        for (const name in migrated.barProfiles) {
            compare(migrated.barProfiles[name].densityPreset, undefined, name);
            compare(migrated.barProfiles[name].barHeight, fixture.barProfiles[name].barHeight, name);
        }
    }

    function test_version4SettingsOnlyLoseThePreset() {
        const version4 = { schemaVersion: 4, densityPreset: "compact", barHeight: 31,
            barProfiles: { work: { densityPreset: "spacious", barHeight: 40 } } };

        const migrated = BarProfileModel.migrate(version4, {}).appearance;

        compare(migrated, { schemaVersion: 5, barHeight: 31,
            barProfiles: { work: { barHeight: 40 } } });
    }
}
