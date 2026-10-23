import QtQuick
import QtTest
import "../config/BarProfileModel.js" as BarProfileModel

TestCase {
    name: "Groups"

    function readFixture(fileName) {
        const request = new XMLHttpRequest();
        request.open("GET", Qt.resolvedUrl("fixtures/" + fileName), false);
        request.send(null);
        return JSON.parse(request.responseText);
    }

    // The real profiles after the element order step, as the group step sees them.
    function migratedState() {
        return BarProfileModel.migrateElementOrder(readFixture("appearance.json"));
    }

    // Groups of a zone as "+"-joined ids; ungrouped elements stand alone.
    function groups(barElements, zoneName) {
        return BarProfileModel.zoneGroups(barElements, zoneName).map(group => group.join("+"));
    }

    function test_anActiveIslandBecomesAGroupFillingTheCenterZone() {
        const media = BarProfileModel.migrateGroups(migratedState()).barProfiles.media;

        compare(media.barElements.left, []);
        compare(media.barElements.right, []);
        compare(groups(media.barElements, "center"),
            ["arch+workspaces+audio+network+battery+clock+notifications+recording"]);
    }

    function test_anIslandKeepsItsLookAndDropsItsOwnSettings() {
        const media = BarProfileModel.migrateGroups(migratedState()).barProfiles.media;

        compare(media.groupRadius, 12);
        compare(media.barTransparent, true);
        compare(media.transparentBarSlanted, false);
        compare(media.barHeight, 34);
        verify(!("statusIsland" in media));
        verify(!("statusIslandRadius" in media));
        verify(!("statusModuleGroups" in media));
    }

    function test_profilesWithoutAnIslandKeepTheirBarAndUseTheCornerRadiusForGroups() {
        const state = migratedState();

        const work = BarProfileModel.migrateGroups(state).barProfiles.work;

        compare(work.barElements, state.barProfiles.work.barElements);
        compare(groups(work.barElements, "center"), ["arch", "workspaces", "notifications"]);
        compare(work.groupRadius, state.barProfiles.work.radius);
        verify(!("statusIsland" in work));
        verify(!("statusModuleGroups" in work));
    }

    function test_theLiveBarIsMigratedToo() {
        const migrated = BarProfileModel.migrateGroups(migratedState());

        compare(groups(migrated.barElements, "left"), ["arch", "workspaces"]);
        verify(!("statusIsland" in migrated));
        compare(migrated.doNotDisturb, readFixture("appearance.json").doNotDisturb);
    }

    function test_numberedGroupsBecomeJoinPrevious() {
        const state = migratedState();
        state.barProfiles.minimal.statusModuleGroups = {
            "audio": 1, "network": 1, "battery": 1, "clock": 2, "notifications": 2,
            "bluetooth": 3, "systemMonitor": 3
        };

        const minimal = BarProfileModel.migrateGroups(state).barProfiles.minimal;

        compare(groups(minimal.barElements, "right"), ["media", "audio+network+battery",
            "clock+notifications", "recording", "bluetooth", "tray"]);
    }

    function test_numberedGroupsOnlyJoinNeighbours() {
        const state = migratedState();
        state.barProfiles.minimal.statusModuleGroups = { "media": 1, "network": 1 };

        const minimal = BarProfileModel.migrateGroups(state).barProfiles.minimal;

        compare(groups(minimal.barElements, "right").slice(0, 3), ["media", "audio", "network"]);
    }

    function test_theGroupMigrationLeavesMigratedDataUntouched() {
        const migrated = BarProfileModel.migrateGroups(migratedState());

        compare(BarProfileModel.migrateGroups(migrated), migrated);
    }

    function test_theGroupMigrationDoesNotChangeItsInput() {
        const state = migratedState();
        const before = JSON.stringify(state);

        BarProfileModel.migrateGroups(state);

        compare(JSON.stringify(state), before);
    }

    function test_theSchemaMigrationRunsTheGroupStepOnce() {
        const migrated = BarProfileModel.migrate(readFixture("appearance.json"),
            readFixture("monitors.json"));

        compare(groups(migrated.appearance.barProfiles.media.barElements, "center"),
            ["arch+workspaces+audio+network+battery+clock+notifications+recording"]);
        verify(!("statusIsland" in migrated.appearance.barProfiles.media));
        compare(BarProfileModel.migrate(migrated.appearance, migrated.monitors), migrated);
    }

    // minimal's left zone is arch, workspaces; right starts -systemMonitor, media, audio, network.
    function minimalElements() {
        return BarProfileModel.migrateGroups(migratedState()).barProfiles.minimal.barElements;
    }

    function test_anElementCanJoinThePreviousOne() {
        const joined = BarProfileModel.setElementJoined(minimalElements(), "workspaces", true);

        compare(groups(joined, "left"), ["arch+workspaces"]);
        compare(BarProfileModel.elementJoined(joined, "workspaces"), true);
        compare(groups(BarProfileModel.setElementJoined(joined, "workspaces", false), "left"),
            ["arch", "workspaces"]);
    }

    function test_theFirstElementOfAZoneCannotJoin() {
        const barElements = minimalElements();

        compare(BarProfileModel.canJoinPrevious(barElements, "arch"), false);
        compare(BarProfileModel.canJoinPrevious(barElements, "workspaces"), true);
        compare(BarProfileModel.setElementJoined(barElements, "arch", true), barElements);
        compare(BarProfileModel.setElementJoined(barElements, "currentApp", true), barElements);
    }

    function test_aDisabledElementIsInNoGroup() {
        let barElements = BarProfileModel.setElementJoined(minimalElements(), "audio", true);
        barElements = BarProfileModel.setElementJoined(barElements, "network", true);

        compare(groups(barElements, "right").slice(0, 1), ["media+audio+network"]);
        const disabled = BarProfileModel.setElementEnabled(barElements, "audio", false);
        compare(groups(disabled, "right").slice(0, 1), ["media+network"]);
        const media = BarProfileModel.setElementEnabled(barElements, "media", false);
        compare(groups(media, "right").slice(0, 1), ["audio+network"]);
    }

    function test_movingToAnotherZoneLeavesTheGroup() {
        let barElements = BarProfileModel.setElementJoined(minimalElements(), "audio", true);
        barElements = BarProfileModel.setElementJoined(barElements, "network", true);

        const moved = BarProfileModel.moveElementToZone(barElements, "audio", "left");

        compare(groups(moved, "left"), ["arch", "workspaces", "audio"]);
        compare(groups(moved, "right").slice(0, 1), ["media+network"]);
        compare(BarProfileModel.elementJoined(moved, "audio"), false);
    }

    function test_movingAnElementToTheFrontOfItsZoneEndsItsJoin() {
        const barElements = BarProfileModel.setElementJoined(minimalElements(), "workspaces", true);

        const moved = BarProfileModel.moveElement(barElements, "workspaces", -1);

        compare(groups(moved, "left"), ["workspaces+arch"]);
        compare(BarProfileModel.elementJoined(moved, "workspaces"), false);
        compare(BarProfileModel.elementJoined(moved, "arch"), true);
    }

    function test_movingAnElementOutOfItsGroupSplitsItCleanly() {
        let barElements = BarProfileModel.setElementJoined(minimalElements(), "audio", true);
        barElements = BarProfileModel.setElementJoined(barElements, "network", true);

        // media+audio+network, battery: network steps out to the right.
        const moved = BarProfileModel.moveElement(barElements, "network", 1);

        compare(groups(moved, "right").slice(0, 3), ["media+audio", "battery", "network"]);
    }

    function test_movingAnElementIntoAGroupDoesNotJoinIt() {
        const barElements = BarProfileModel.setElementJoined(minimalElements(), "audio", true);

        // media+audio, network: network steps in between.
        const moved = BarProfileModel.moveElement(barElements, "network", -1);

        compare(groups(moved, "right").slice(0, 3), ["media", "network", "audio"]);
    }

    function test_movingWithinAGroupKeepsTheGroup() {
        let barElements = BarProfileModel.setElementJoined(minimalElements(), "audio", true);
        barElements = BarProfileModel.setElementJoined(barElements, "network", true);

        const moved = BarProfileModel.moveElement(barElements, "network", -1);

        compare(groups(moved, "right").slice(0, 1), ["media+network+audio"]);
    }

    function test_normalizingClearsTheJoinOfTheFirstElement() {
        const normalized = BarProfileModel.normalizeBarElements({
            left: [{ id: "arch", enabled: true, joinPrevious: true }]
        });

        compare(BarProfileModel.elementJoined(normalized, "arch"), false);
    }

    function test_groupRadiusIsPartOfAProfile() {
        const state = BarProfileModel.migrateGroups(migratedState());

        compare(BarProfileModel.editProfile(state, "media").groupRadius, 12);
        verify(!("statusIsland" in BarProfileModel.editProfile(state, "media")));
        state.groupRadius = 20;
        const saved = BarProfileModel.saveProfile(state, "minimal").barProfiles.minimal;
        compare(saved.groupRadius, 20);
        verify(!("statusIsland" in saved));
        verify(!("statusModuleGroups" in saved));
    }
}
