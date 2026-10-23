import QtQuick
import QtTest
import "../config/BarProfileModel.js" as BarProfileModel
import "../config/SchemaMigrations.js" as SchemaMigrations

TestCase {
    name: "BarElements"

    Fixtures {
        id: fixtures
    }

    // A zone as ids in order; disabled elements are prefixed with "-".
    function zone(barElements, zoneName) {
        return barElements[zoneName].map(element => (element.enabled ? "" : "-") + element.id);
    }

    function test_migratingMinimalKeepsTheBarItShowedBefore() {
        const profile = fixtures.read("appearance.json").barProfiles.minimal;

        const barElements = SchemaMigrations.migrateBarElements(profile);

        compare(zone(barElements, "left"), ["arch", "workspaces"]);
        compare(zone(barElements, "center"), ["currentApp"]);
        compare(zone(barElements, "right"), ["-systemMonitor", "media", "audio", "network",
            "battery", "clock", "notifications", "recording", "bluetooth", "tray"]);
    }

    function test_migratingMediaKeepsTheBarItShowedBefore() {
        const profile = fixtures.read("appearance.json").barProfiles.media;

        const barElements = SchemaMigrations.migrateBarElements(profile);

        compare(zone(barElements, "left"), ["arch", "-systemMonitor", "-currentApp"]);
        compare(zone(barElements, "center"), ["workspaces"]);
        compare(zone(barElements, "right"), ["-media", "audio", "network", "battery", "clock",
            "notifications", "recording", "-bluetooth", "-tray"]);
    }

    function test_migratingPresentationKeepsTheBarItShowedBefore() {
        const profile = fixtures.read("appearance.json").barProfiles.presentation;

        const barElements = SchemaMigrations.migrateBarElements(profile);

        compare(zone(barElements, "left"), ["-arch", "-systemMonitor", "-currentApp",
            "workspaces", "-media"]);
        compare(zone(barElements, "center"), []);
        compare(zone(barElements, "right"), ["-audio", "network", "battery", "clock",
            "notifications", "recording", "-bluetooth", "-tray"]);
    }

    function test_migratingWorkKeepsTheBarItShowedBefore() {
        const profile = fixtures.read("appearance.json").barProfiles.work;

        const barElements = SchemaMigrations.migrateBarElements(profile);

        compare(zone(barElements, "left"), ["systemMonitor", "currentApp"]);
        compare(zone(barElements, "center"), ["arch", "workspaces", "notifications"]);
        compare(zone(barElements, "right"), ["media", "audio", "network", "battery", "clock",
            "recording", "bluetooth", "tray"]);
    }

    function test_theElementOrderMigrationStepConvertsTheLiveBarAndEveryProfile() {
        const state = fixtures.read("appearance.json");

        const migrated = SchemaMigrations.migrateElementOrder(state);

        compare(zone(migrated.barElements, "center"), ["currentApp"]);
        compare(zone(migrated.barProfiles.work.barElements, "left"), ["systemMonitor", "currentApp"]);
        for (const layout of [migrated, migrated.barProfiles.media]) {
            verify(!("statusModuleOrder" in layout));
            verify(!("statusModuleEnabled" in layout));
            verify(!("statusModulePlacement" in layout));
            verify(!("barElementEnabled" in layout));
            verify(!("barElementPlacement" in layout));
        }
        compare(migrated.barProfiles.media.statusModuleGroups, {});
        compare(migrated.barProfiles.media.barHeight, 34);
        compare(migrated.doNotDisturb, state.doNotDisturb);
        verify("statusModuleOrder" in state);
    }

    function test_theElementOrderMigrationStepLeavesMigratedDataUntouched() {
        const migrated = SchemaMigrations.migrateElementOrder(fixtures.read("appearance.json"));
        migrated.barElements.left.reverse();

        compare(SchemaMigrations.migrateElementOrder(migrated), migrated);
    }

    function minimalElements() {
        return SchemaMigrations.migrateBarElements(fixtures.read("appearance.json").barProfiles.minimal);
    }

    function test_movingAnElementToAnotherZonePutsItAtTheEnd() {
        const barElements = minimalElements();

        const moved = BarProfileModel.moveElementToZone(barElements, "battery", "left");

        compare(zone(moved, "left"), ["arch", "workspaces", "battery"]);
        compare(zone(moved, "right"), ["-systemMonitor", "media", "audio", "network",
            "clock", "notifications", "recording", "bluetooth", "tray"]);
        compare(zone(barElements, "left"), ["arch", "workspaces"]);
    }

    function test_movingAnElementToItsOwnZoneKeepsItsPlace() {
        const barElements = minimalElements();

        compare(BarProfileModel.moveElementToZone(barElements, "arch", "left"), barElements);
    }

    function test_anyElementCanGoInFrontOfAnyOther() {
        let barElements = BarProfileModel.moveElementToZone(minimalElements(), "battery", "left");

        barElements = BarProfileModel.moveElement(barElements, "battery", -1);
        barElements = BarProfileModel.moveElement(barElements, "battery", -1);

        compare(zone(barElements, "left"), ["battery", "arch", "workspaces"]);
    }

    function test_movingDownReordersWithinTheZone() {
        const moved = BarProfileModel.moveElement(minimalElements(), "arch", 1);

        compare(zone(moved, "left"), ["workspaces", "arch"]);
    }

    function test_movingPastTheEdgesOfAZoneDoesNothing() {
        const barElements = minimalElements();

        compare(BarProfileModel.moveElement(barElements, "arch", -1), barElements);
        compare(BarProfileModel.moveElement(barElements, "workspaces", 1), barElements);
        compare(BarProfileModel.moveElement(barElements, "currentApp", 1), barElements);
    }

    function test_elementsCanBeTurnedOffAndOn() {
        const barElements = minimalElements();

        const off = BarProfileModel.setElementEnabled(barElements, "arch", false);
        const on = BarProfileModel.setElementEnabled(off, "systemMonitor", true);

        compare(zone(on, "left"), ["-arch", "workspaces"]);
        compare(zone(on, "right")[0], "systemMonitor");
        compare(BarProfileModel.elementEnabled(on, "arch"), false);
        compare(BarProfileModel.elementEnabled(on, "systemMonitor"), true);
        compare(zone(barElements, "left"), ["arch", "workspaces"]);
    }

    function test_theZoneOfAnElementIsWhereItIsListed() {
        const barElements = minimalElements();

        compare(BarProfileModel.elementZone(barElements, "workspaces"), "left");
        compare(BarProfileModel.elementZone(barElements, "currentApp"), "center");
        compare(BarProfileModel.elementZone(barElements, "clock"), "right");
    }

    function test_normalizingListsEveryElementOnce() {
        const normalized = BarProfileModel.normalizeBarElements({
            left: [{ id: "clock", enabled: true }, { id: "bogus", enabled: true }],
            center: [{ id: "clock", enabled: false }]
        });

        compare(zone(normalized, "left"), ["clock"]);
        compare(zone(normalized, "center"), []);
        compare(zone(normalized, "right"), ["arch", "systemMonitor", "currentApp", "workspaces",
            "notifications", "recording", "media", "audio", "bluetooth", "tray", "network",
            "battery"]);
        compare(BarProfileModel.normalizeBarElements(minimalElements()), minimalElements());
    }

    function test_editingAMigratedProfileShowsItsBarElements() {
        const state = fixtures.startedBarState();

        const after = fixtures.withChanges(state, BarProfileModel.editProfile(state, "work"));

        const edited = BarProfileModel.editedProfile(after);
        compare(zone(edited.barElements, "center"), ["arch", "workspaces", "notifications"]);
        verify(!("statusModuleOrder" in edited));
        verify(!("barElementEnabled" in edited));
    }

    function test_savingAProfileStoresItsPendingBarElements() {
        const state = fixtures.startedBarState();
        const barElements = BarProfileModel.editedProfile(state).barElements;
        const moved = fixtures.edited(state,
            { barElements: BarProfileModel.moveElementToZone(barElements, "battery", "left") });

        const changes = BarProfileModel.saveProfile(moved);

        compare(zone(changes.barProfiles.minimal.barElements, "left"),
            ["arch", "workspaces", "battery"]);
        verify(!("statusModuleOrder" in changes.barProfiles.minimal));
    }
}
