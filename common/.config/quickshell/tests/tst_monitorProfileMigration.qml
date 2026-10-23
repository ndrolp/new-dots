import QtQuick
import QtTest
import "../config/BarProfileModel.js" as BarProfileModel

TestCase {
    name: "MonitorProfileMigration"

    readonly property string aoc: "AOC Q27G42XE 2S6S1HA031479"
    readonly property string philips: "Philips Consumer Electronics Company PHL 243V7 0x00009A4C"
    readonly property string samsung: "Samsung Display Corp. ATNA40HQ01-0"

    function readFixture(fileName) {
        const request = new XMLHttpRequest();
        request.open("GET", Qt.resolvedUrl("fixtures/" + fileName), false);
        request.send(null);
        return JSON.parse(request.responseText);
    }

    function migrateFixtures(prepare) {
        const appearance = readFixture("appearance.json");
        const monitors = readFixture("monitors.json");
        if (prepare)
            prepare(appearance, monitors);
        return BarProfileModel.migrate(appearance, monitors);
    }

    function test_unassignedMonitorsGetTheOldActiveProfile() {
        const displaySettings = migrateFixtures().monitors.displaySettings;

        compare(displaySettings[philips].barProfile, "minimal");
        compare(displaySettings[aoc].barProfile, "minimal");
        compare(displaySettings[samsung].barProfile, "minimal");
        compare(displaySettings["default"].barProfile, "minimal");
    }

    function test_explicitAssignmentsAreKept() {
        const displaySettings = migrateFixtures((appearance, monitors) => {
            monitors.displaySettings[philips].barProfile = "work";
        }).monitors.displaySettings;

        compare(displaySettings[philips].barProfile, "work");
        compare(displaySettings[aoc].barProfile, "minimal");
    }

    function test_theActiveProfileBecomesTheEditedProfile() {
        const appearance = migrateFixtures(appearance => {
            appearance.activeBarProfile = "media";
        }).appearance;

        compare(appearance.activeBarProfile, undefined);
        compare(appearance.editingBarProfile, "media");
    }

    function test_migratedStateIsLeftUntouched() {
        const once = migrateFixtures();
        const twice = BarProfileModel.migrate(once.appearance, once.monitors);

        compare(twice, once);
    }
}
