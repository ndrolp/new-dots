import QtQuick
import QtTest
import "../config/BarProfileModel.js" as BarProfileModel
import "../config/SchemaMigrations.js" as SchemaMigrations

// Density presets are a shortcut that fills in the bar sizes of the edited
// profile; the preset itself is never stored.
TestCase {
    name: "DensityPresets"

    Fixtures {
        id: fixtures
    }

    function test_applyingAPresetFillsTheSizesAndMarksTheProfileModified() {
        const state = fixtures.startedBarState();

        const after = fixtures.edited(state, BarProfileModel.densityPresetChanges("spacious"));

        compare(BarProfileModel.editedProfile(after).barHeight, 38);
        compare(BarProfileModel.editedProfile(after).textSize, 15);
        verify(BarProfileModel.isModified(after));
    }

    function test_savingAfterAPresetLeavesNoTraceOfThePreset() {
        const applied = fixtures.edited(fixtures.startedBarState(),
            BarProfileModel.densityPresetChanges("compact"));

        const saved = fixtures.withChanges(applied, BarProfileModel.saveProfile(applied));

        const profile = saved.barProfiles[saved.editingBarProfile];
        compare(profile.barHeight, 30);
        compare(profile.densityPreset, undefined);
    }

    function test_discardingAfterAPresetRestoresTheSavedSizes() {
        const state = fixtures.startedBarState();
        const applied = fixtures.edited(state, BarProfileModel.densityPresetChanges("spacious"));

        const discarded = fixtures.withChanges(applied, BarProfileModel.discardChanges(applied));

        compare(BarProfileModel.editedProfile(discarded).barHeight, 34);
        verify(!BarProfileModel.isModified(discarded));
    }

    function test_theMatchingPresetIsDerivedFromTheSizes() {
        const state = fixtures.edited(fixtures.startedBarState(),
            BarProfileModel.densityPresetChanges("spacious"));
        compare(BarProfileModel.matchingDensityPreset(BarProfileModel.editedProfile(state)),
            "spacious");

        const changed = fixtures.edited(state, { barHeight: 99 });
        compare(BarProfileModel.matchingDensityPreset(BarProfileModel.editedProfile(changed)), "");
    }

    function test_migrationRemovesTheStoredPresetFromEveryProfile() {
        const fixture = fixtures.read("appearance.json");
        verify(fixture.densityPreset !== undefined);

        const migrated = SchemaMigrations.migrate(fixture, fixtures.read("monitors.json")).appearance;

        compare(migrated.densityPreset, undefined);
        for (const name in migrated.barProfiles) {
            compare(migrated.barProfiles[name].densityPreset, undefined, name);
            compare(migrated.barProfiles[name].barHeight, fixture.barProfiles[name].barHeight, name);
        }
    }

    function test_version4SettingsOnlyLoseThePreset() {
        const version4 = { schemaVersion: 4, densityPreset: "compact", barHeight: 31,
            barProfiles: { work: { densityPreset: "spacious", barHeight: 40 } } };

        const migrated = SchemaMigrations.migrate(version4, {}).appearance;

        compare(migrated.densityPreset, undefined);
        compare(migrated.barProfiles.work.densityPreset, undefined);
        compare(migrated.barProfiles.work.barHeight, 40);
    }

    // Nothing reads the workspace padding, so presets no longer set it and the
    // migration drops it from every saved profile.
    function test_presetsDoNotSetTheWorkspacePadding() {
        for (const preset of ["compact", "balanced", "spacious"])
            compare(BarProfileModel.densityPresetChanges(preset).workspacePadding, undefined, preset);
    }

    function test_migrationDropsTheWorkspacePaddingFromEveryProfile() {
        const version22 = { schemaVersion: 22, barProfiles: {
            work: { workspacePadding: 3, barHeight: 34 },
            media: { workspacePadding: 5 }
        } };

        const profiles = SchemaMigrations.migrate(version22, {}).appearance.barProfiles;

        compare(profiles.work.workspacePadding, undefined);
        compare(profiles.work.barHeight, 34);
        compare(profiles.media.workspacePadding, undefined);
    }

    function test_migratedFixtureHasNoWorkspacePadding() {
        const migrated = SchemaMigrations.migrate(fixtures.read("appearance.json"),
            fixtures.read("monitors.json")).appearance;

        compare(migrated.workspacePadding, undefined);
        for (const name in migrated.barProfiles)
            compare(migrated.barProfiles[name].workspacePadding, undefined, name);
    }
}
