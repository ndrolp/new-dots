import QtQuick
import QtTest
import "../config/BarProfileModel.js" as BarProfileModel
import "../config/SchemaMigrations.js" as SchemaMigrations

TestCase {
    name: "BarStyleMigration"

    Fixtures {
        id: fixtures
    }

    // Bar profiles of schema version 15, which stored the bar style as two
    // switches, brought to the current schema.
    function migratedProfiles(profiles) {
        return SchemaMigrations.migrate({ schemaVersion: 15, barProfiles: profiles }, {})
            .appearance.barProfiles;
    }

    function test_eachSavedProfileKeepsTheBarStyleItShowed_data() {
        return [
            { tag: "opaque", profile: { barTransparent: false, transparentBarSlanted: false },
                barStyle: "opaque" },
            { tag: "transparent", profile: { barTransparent: true, transparentBarSlanted: false },
                barStyle: "transparent" },
            { tag: "docked", profile: { barTransparent: true, transparentBarSlanted: true },
                barStyle: "docked" },
            { tag: "transparent without the docked switch", profile: { barTransparent: true },
                barStyle: "transparent" },
            { tag: "opaque without the transparent switch", profile: { transparentBarSlanted: false },
                barStyle: "opaque" }
        ];
    }

    function test_eachSavedProfileKeepsTheBarStyleItShowed(data) {
        const profile = migratedProfiles({ saved: data.profile }).saved;

        compare(profile.barStyle, data.barStyle);
        verify(profile.barTransparent === undefined);
        verify(profile.transparentBarSlanted === undefined);
    }

    function test_aProfileThatSavedNeitherSwitchStaysOpaque() {
        const profile = migratedProfiles({ saved: { barHeight: 30 } }).saved;

        verify(profile.barStyle === undefined);
        compare(BarProfileModel.completeProfile(profile).barStyle, "opaque");
    }

    // The docked switch on an opaque bar only made its pills transparent.
    function test_anOpaqueBarWithTheDockedSwitchKeepsItsTransparentPills() {
        const profile = migratedProfiles({ saved: {
            barTransparent: false, transparentBarSlanted: true, pillsTransparent: false
        } }).saved;

        compare(profile.barStyle, "opaque");
        compare(profile.pillsTransparent, true);
    }

    function test_theOtherBarStylesKeepTheirPills_data() {
        return [
            { tag: "opaque", profile: { barTransparent: false, transparentBarSlanted: false } },
            { tag: "transparent", profile: { barTransparent: true, transparentBarSlanted: false } },
            { tag: "docked", profile: { barTransparent: true, transparentBarSlanted: true } }
        ];
    }

    function test_theOtherBarStylesKeepTheirPills(data) {
        const profile = migratedProfiles({ saved: Object.assign({ pillsTransparent: false },
            data.profile) }).saved;

        compare(profile.pillsTransparent, false);
    }

    function test_theRealConfigKeepsEveryProfilesBarStyle() {
        const profiles = fixtures.migrated().appearance.barProfiles;

        // The fixture's minimal profile was opaque with the docked switch on.
        compare(profiles.minimal.barStyle, "opaque");
        compare(profiles.minimal.pillsTransparent, true);
        // Its media profile had the status island, which made the bar transparent.
        compare(profiles.media.barStyle, "transparent");
        compare(profiles.presentation.barStyle, "docked");
        compare(profiles.work.barStyle, "transparent");
    }
}
