import QtQuick
import QtTest
import "../config/BarProfileModel.js" as BarProfileModel
import "../config/SchemaMigrations.js" as SchemaMigrations

TestCase {
    name: "MonitorProfileMigration"

    readonly property string aoc: "AOC Q27G42XE 2S6S1HA031479"
    readonly property string philips: "Philips Consumer Electronics Company PHL 243V7 0x00009A4C"
    readonly property string samsung: "Samsung Display Corp. ATNA40HQ01-0"

    Fixtures {
        id: fixtures
    }

    function migrateFixtures(prepare) {
        const appearance = fixtures.read("appearance.json");
        const monitors = fixtures.read("monitors.json");
        if (prepare)
            prepare(appearance, monitors);
        return SchemaMigrations.migrate(appearance, monitors);
    }

    function test_unassignedMonitorsGetTheOldActiveProfile() {
        const displaySettings = migrateFixtures().monitors.displaySettings;

        compare(displaySettings[philips].barProfile, "minimal");
        compare(displaySettings[aoc].barProfile, "minimal");
        compare(displaySettings[samsung].barProfile, "minimal");
    }

    function test_everyKnownMonitorGetsAnExplicitEntryAndNoDefaultEntryIsLeft() {
        const displaySettings = migrateFixtures().monitors.displaySettings;

        compare(Object.keys(displaySettings).sort(), [aoc, philips, samsung]);
        for (const name of [aoc, philips, samsung]) {
            compare(displaySettings[name].barVisible, true, name);
            verify(displaySettings[name].desktopWidgets !== undefined, name);
        }
    }

    function test_monitorsOnlyKnownThroughTheDefaultEntryKeepItsBarVisibility() {
        const displaySettings = migrateFixtures((appearance, monitors) => {
            monitors.displaySettings["default"].barVisible = false;
        }).monitors.displaySettings;

        compare(displaySettings[aoc].barVisible, false);
        compare(displaySettings[philips].barVisible, true);
    }

    function test_onlyRealMonitorsUseAProfile() {
        const displaySettings = migrateFixtures().monitors.displaySettings;

        compare(BarProfileModel.monitorsUsingProfile(displaySettings, "minimal").sort(),
            [aoc, philips, samsung]);
    }

    function test_explicitAssignmentsAreKept() {
        const displaySettings = migrateFixtures((appearance, monitors) => {
            monitors.displaySettings[philips].barProfile = "work";
        }).monitors.displaySettings;

        compare(displaySettings[philips].barProfile, "work");
        compare(displaySettings[aoc].barProfile, "minimal");
    }

    function test_noActiveOrEditedProfileIsStored() {
        const appearance = migrateFixtures(appearance => {
            appearance.activeBarProfile = "media";
        }).appearance;

        compare(appearance.activeBarProfile, undefined);
        compare(appearance.editingBarProfile, undefined);
    }

    function test_migratedStateIsLeftUntouched() {
        const once = migrateFixtures();
        const twice = SchemaMigrations.migrate(once.appearance, once.monitors);

        compare(twice, once);
    }
}
