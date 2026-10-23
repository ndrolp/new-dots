import QtQuick
import QtTest
import "../config/SchemaMigrations.js" as SchemaMigrations
import "../config/DesktopWidgetsModel.js" as DesktopWidgetsModel

TestCase {
    name: "DesktopWidgetsMigration"

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

    // What the real desktop showed: the live (top-level) values of the active
    // profile `minimal`.
    readonly property var liveDesktop: ({
        order: ["calendar", "media", "weather", "network", "system"],
        backgroundClock: {
            enabled: true, position: "bottom-right", size: 96, opacity: 100,
            dateFormat: "full", calendarEnabled: true
        },
        media: { enabled: true, position: "bottom-left" },
        system: { enabled: true, position: "bottom-left" },
        calendar: { enabled: false, position: "top-left" },
        network: { enabled: true, position: "bottom-left" },
        weather: { enabled: false, position: "bottom-left", location: "Ourense, ES" }
    })

    function test_migrationMarksTheFilesWithTheSchemaVersion() {
        const migrated = migrateFixtures();

        compare(migrated.appearance.schemaVersion, SchemaMigrations.schemaVersion);
        verify(SchemaMigrations.schemaVersion >= 1);
    }

    function test_unassignedMonitorsKeepTheDesktopTheyShowed() {
        const migrated = migrateFixtures();
        const displaySettings = migrated.monitors.displaySettings;

        compare(displaySettings[aoc].desktopWidgets, liveDesktop);
        compare(displaySettings[philips].desktopWidgets, liveDesktop);
        compare(displaySettings[samsung].desktopWidgets, liveDesktop);
    }

    function test_monitorsKeepTheirOtherDisplaySettings() {
        const migrated = migrateFixtures();

        compare(migrated.monitors.displaySettings[philips].barVisible, true);
        compare(migrated.monitors.assignments, fixtures.read("monitors.json").assignments);
    }

    function test_aMonitorReceivesTheDesktopOfItsAssignedProfile() {
        const migrated = migrateFixtures((appearance, monitors) => {
            monitors.displaySettings[aoc] = { barVisible: true, barProfile: "media" };
        });
        const desktop = migrated.monitors.displaySettings[aoc].desktopWidgets;

        compare(desktop.backgroundClock.enabled, false);
        compare(desktop.weather.enabled, true);
        compare(migrated.monitors.displaySettings[aoc].barProfile, "media");
        compare(migrated.monitors.displaySettings[philips].desktopWidgets, liveDesktop);
    }

    function test_liveValuesOfTheActiveProfileWinOverItsSavedCopy() {
        const migrated = migrateFixtures((appearance, monitors) => {
            appearance.desktopCalendarEnabled = true;
            monitors.displaySettings[aoc] = { barProfile: "minimal" };
        });

        compare(migrated.monitors.displaySettings[aoc].desktopWidgets.calendar.enabled, true);
        compare(migrated.monitors.displaySettings[samsung].desktopWidgets.calendar.enabled, true);
    }

    function test_monitorsSharingAProfileGetTheirOwnCopy() {
        const migrated = migrateFixtures((appearance, monitors) => {
            monitors.displaySettings[aoc] = { barProfile: "work" };
            monitors.displaySettings[samsung] = { barProfile: "work" };
        });
        const displaySettings = migrated.monitors.displaySettings;

        displaySettings[aoc].desktopWidgets.media.enabled = false;

        compare(displaySettings[samsung].desktopWidgets.media.enabled, true);
    }

    function test_aMonitorThatHidTheBackgroundClockKeepsItHidden() {
        const migrated = migrateFixtures((appearance, monitors) => {
            monitors.displaySettings[philips].backgroundClockVisible = false;
        });
        const philipsSettings = migrated.monitors.displaySettings[philips];

        compare(philipsSettings.desktopWidgets.backgroundClock.enabled, false);
        verify(!("backgroundClockVisible" in philipsSettings));
        compare(migrated.monitors.displaySettings[samsung].desktopWidgets.backgroundClock.enabled, true);
    }

    function test_barProfilesNoLongerHoldDesktopOrNotificationSettings() {
        const migrated = migrateFixtures();
        const names = ["minimal", "media", "presentation", "work"];

        compare(Object.keys(migrated.appearance.barProfiles).sort(), names.sort());

        for (let index = 0; index < names.length; index++) {
            const profile = migrated.appearance.barProfiles[names[index]];

            for (const key in profile) {
                verify(key.indexOf("backgroundClock") !== 0, names[index] + "." + key);
                verify(key.indexOf("desktop") !== 0, names[index] + "." + key);
                verify(key !== "notificationPopupLocation", names[index] + "." + key);
            }
        }
    }

    function test_barProfilesKeepEverythingAboutTheBar() {
        const original = fixtures.read("appearance.json");
        const migrated = migrateFixtures();

        compare(migrated.appearance.barProfiles.media.barHeight, 34);
        compare(migrated.appearance.barProfiles.media.groupRadius,
            original.barProfiles.media.statusIslandRadius);
        // "work" saved no opacity: it keeps the one its monitors drew.
        compare(migrated.appearance.barProfiles.work.barOpacity, original.barOpacity);
    }

    function test_theNotificationPopupLocationBecomesGlobal() {
        const migrated = migrateFixtures();

        compare(migrated.appearance.notificationPopupLocation, "top-right");
        verify(!("backgroundClockEnabled" in migrated.appearance));
        verify(!("desktopWidgetOrder" in migrated.appearance));
    }

    function test_migrationAlsoConvertsTheBarElements() {
        const migrated = migrateFixtures();

        verify(migrated.appearance.barProfiles.media.barElements !== undefined);
        verify(!("statusModuleOrder" in migrated.appearance.barProfiles.media));
    }

    function test_migrationDoesNotChangeItsInput() {
        const appearance = fixtures.read("appearance.json");
        const monitors = fixtures.read("monitors.json");

        SchemaMigrations.migrate(appearance, monitors);

        compare(appearance, fixtures.read("appearance.json"));
        compare(monitors, fixtures.read("monitors.json"));
    }

    function test_aMigratedFileDoesNotChangeWhenLoadedAgain() {
        const once = migrateFixtures();
        const onceCopy = JSON.parse(JSON.stringify(once));

        const twice = SchemaMigrations.migrate(once.appearance, once.monitors);

        compare(twice, onceCopy);
        verify(!SchemaMigrations.needsMigration(once.appearance));
        verify(SchemaMigrations.needsMigration(fixtures.read("appearance.json")));
    }

    function test_changingTheBarProfileDoesNotTouchDesktopWidgets() {
        const migrated = migrateFixtures();

        const media = migrated.appearance.barProfiles.media;

        verify(!("backgroundClockEnabled" in media));
        verify(!("desktopWeatherEnabled" in media));
        verify(!("notificationPopupLocation" in media));
    }

    function test_aMonitorWithoutSettingsUsesTheBuiltInDesktop() {
        const displaySettings = migrateFixtures().monitors.displaySettings;
        displaySettings["default"] = { desktopWidgets: { media: { enabled: true } } };

        compare(DesktopWidgetsModel.desktopWidgetsFor(displaySettings, "HDMI-9").media.enabled, false);
        compare(DesktopWidgetsModel.desktopWidgetsFor({}, "HDMI-9").backgroundClock.enabled, true);
    }

    function test_editingADesktopWidgetOnlyChangesThatMonitor() {
        const displaySettings = migrateFixtures().monitors.displaySettings;

        const updated = DesktopWidgetsModel.setDesktopWidgetSetting(
            displaySettings, philips, "backgroundClock", "enabled", false);

        compare(updated[philips].desktopWidgets.backgroundClock.enabled, false);
        compare(updated[philips].barVisible, true);
        compare(updated[aoc].desktopWidgets.backgroundClock.enabled, true);
        compare(displaySettings[philips].desktopWidgets.backgroundClock.enabled, true);
    }

    function test_reorderingDesktopWidgetsOnlyChangesThatMonitor() {
        const displaySettings = migrateFixtures().monitors.displaySettings;

        const updated = DesktopWidgetsModel.moveDesktopWidget(displaySettings, aoc, "media", -1);

        compare(DesktopWidgetsModel.desktopWidgetOrder(updated[aoc].desktopWidgets),
            ["media", "calendar", "weather", "network", "system"]);
        compare(updated[samsung].desktopWidgets.order, liveDesktop.order);
        compare(DesktopWidgetsModel.moveDesktopWidget(updated, aoc, "media", -1), updated);
    }

    function test_editingAMonitorWithoutSettingsStartsFromTheBuiltInDesktop() {
        const displaySettings = migrateFixtures().monitors.displaySettings;

        const updated = DesktopWidgetsModel.setDesktopWidgetSetting(
            displaySettings, "HDMI-9", "weather", "location", "Vigo, ES");

        compare(updated["HDMI-9"].desktopWidgets.weather.location, "Vigo, ES");
        compare(updated["HDMI-9"].desktopWidgets.media, { enabled: false, position: "bottom-left" });
        compare(updated[aoc].desktopWidgets.weather.location, "Ourense, ES");
    }
}
