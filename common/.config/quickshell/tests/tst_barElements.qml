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
            "notifications", "recording", "media", "-cava", "audio", "bluetooth", "tray",
            "network", "battery"]);
        const once = BarProfileModel.normalizeBarElements(minimalElements());
        compare(BarProfileModel.normalizeBarElements(once), once);
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

    function element(barElements, id) {
        for (const zoneName of ["left", "center", "right"]) {
            const found = barElements[zoneName].find(entry => entry.id === id);
            if (found)
                return found;
        }
        return null;
    }

    function test_migrationStoresElementOptionsOnTheirElements() {
        const minimal = fixtures.migrated().appearance.barProfiles.minimal;

        compare(element(minimal.barElements, "audio").options, { meterVisible: false });
        compare(element(minimal.barElements, "battery").options, { percentageVisible: true });
        compare(element(minimal.barElements, "workspaces").options.appCountVisible, false);
        compare(element(minimal.barElements, "workspaces").options.hideEmpty, false);
        compare(element(minimal.barElements, "workspaces").options.glyphs.length, 20);
        for (const key of ["audioMeterVisible", "batteryPercentageVisible", "mediaTitleVisible",
                "notificationBadgeVisible", "workspaceGlyphsEnabled", "workspaceGlyphs",
                "hideEmptyWorkspaces", "workspaceAppCountVisible"])
            verify(!(key in minimal), key);
    }

    function test_optionsAProfileDidNotSaveKeepWhatItsMonitorsDrew() {
        const work = fixtures.migrated().appearance.barProfiles.work;

        // "work" saved no meter setting; its monitors drew the top-level one.
        compare(element(work.barElements, "audio").options.meterVisible, false);
    }

    function test_anElementOptionNobodySetHasItsDefault() {
        const barElements = BarProfileModel.normalizeBarElements({
            right: [{ id: "battery", enabled: true }]
        });

        compare(BarProfileModel.elementOption(barElements, "battery", "percentageVisible"), true);
        compare(BarProfileModel.elementOption(barElements, "workspaces", "hideEmpty"), false);
    }

    function test_settingAnElementOptionOnlyChangesThatElement() {
        const barElements = BarProfileModel.editedProfile(fixtures.startedBarState()).barElements;

        const updated = BarProfileModel.setElementOption(barElements, "battery",
            "percentageVisible", false);

        compare(BarProfileModel.elementOption(updated, "battery", "percentageVisible"), false);
        compare(BarProfileModel.elementOption(barElements, "battery", "percentageVisible"), true);
        compare(element(updated, "audio"), element(barElements, "audio"));
    }

    function test_cavaIsInEveryDefaultProfileDisabledNextToMediaAndAudio() {
        const profiles = BarProfileModel.defaultBarProfiles();

        for (const name in profiles) {
            const right = zone(profiles[name].barElements, "right").map(id => id.replace("-", ""));
            compare(right.indexOf("cava"), right.indexOf("media") + 1, name);
            compare(right.indexOf("audio"), right.indexOf("cava") + 1, name);
            compare(BarProfileModel.elementEnabled(profiles[name].barElements, "cava"), false, name);
        }
    }

    function test_aProfileSavedBeforeCavaExistedShowsItDisabled() {
        const state = fixtures.startedBarState();

        for (const name in state.barProfiles) {
            const barElements = BarProfileModel.savedProfile(state, name).barElements;
            const mediaZone = BarProfileModel.elementZone(barElements, "media");
            compare(BarProfileModel.elementZone(barElements, "cava"), mediaZone, name);
            compare(BarProfileModel.elementEnabled(barElements, "cava"), false, name);
            const ids = zone(barElements, mediaZone).map(id => id.replace("-", ""));
            compare(ids.indexOf("cava"), ids.indexOf("media") + 1, name);
            if (BarProfileModel.elementZone(barElements, "audio") === mediaZone)
                compare(ids.indexOf("audio"), ids.indexOf("cava") + 1, name);
        }
    }

    function test_theRecordingIndicatorIsInEveryDefaultProfileEnabledAfterNotifications() {
        const profiles = BarProfileModel.defaultBarProfiles();

        for (const name in profiles) {
            const barElements = profiles[name].barElements;
            const zoneName = BarProfileModel.elementZone(barElements, "notifications");
            const ids = zone(barElements, zoneName).map(id => id.replace("-", ""));
            compare(ids.indexOf("recording"), ids.indexOf("notifications") + 1, name);
            compare(BarProfileModel.elementEnabled(barElements, "recording"), true, name);
        }
    }

    function test_aProfileWithoutTheRecordingIndicatorGetsItEnabledAfterNotifications() {
        const barElements = BarProfileModel.normalizeBarElements({
            center: [{ id: "notifications", enabled: true }, { id: "clock", enabled: true }]
        });

        compare(zone(barElements, "center").slice(0, 2), ["notifications", "recording"]);
        compare(BarProfileModel.elementEnabled(barElements, "recording"), true);
    }

    function test_theRecordingIndicatorCanBeMovedToAnotherZone() {
        const moved = BarProfileModel.moveElementToZone(minimalElements(), "recording", "left");

        compare(zone(moved, "left"), ["arch", "workspaces", "recording"]);
        compare(BarProfileModel.elementEnabled(moved, "recording"), true);
    }

    // A missing element goes right after the element it follows by default,
    // in that element's zone; the first element, which follows none, goes
    // right before the one it precedes.
    function test_aMissingElementIsAddedNextToItsDefaultNeighbours() {
        const afterMedia = BarProfileModel.normalizeBarElements({
            left: [{ id: "media", enabled: true }, { id: "clock", enabled: true }],
            right: [{ id: "audio", enabled: true }]
        });
        compare(zone(afterMedia, "left").slice(0, 3), ["media", "-cava", "clock"]);

        const beforeSystemMonitor = BarProfileModel.normalizeBarElements({
            center: [{ id: "clock", enabled: true }, { id: "systemMonitor", enabled: true }]
        });
        compare(zone(beforeSystemMonitor, "center").slice(0, 3), ["clock", "arch", "systemMonitor"]);
    }

    function test_aProfileThatListsCavaKeepsItEnabled() {
        const barElements = BarProfileModel.normalizeBarElements({
            left: [{ id: "cava", enabled: true }]
        });

        compare(BarProfileModel.elementZone(barElements, "cava"), "left");
        compare(BarProfileModel.elementEnabled(barElements, "cava"), true);
    }

    function test_cavaDrawsTwelveBlueBarsThreePixelsWideByDefault() {
        const barElements = BarProfileModel.normalizeBarElements({});

        compare(BarProfileModel.elementOptions(barElements, "cava"),
            { barCount: 12, barWidth: 3, color: "blue" });
    }

    function test_cavaKeepsItsBarCountAndWidthWithinTheirRanges() {
        const tooMuch = BarProfileModel.normalizeBarElements({
            right: [{ id: "cava", enabled: true, options: { barCount: 40, barWidth: 12 } }]
        });
        const tooLittle = BarProfileModel.normalizeBarElements({
            right: [{ id: "cava", enabled: true, options: { barCount: 2, barWidth: 0 } }]
        });

        compare(BarProfileModel.elementOption(tooMuch, "cava", "barCount"), 32);
        compare(BarProfileModel.elementOption(tooMuch, "cava", "barWidth"), 8);
        compare(BarProfileModel.elementOption(tooLittle, "cava", "barCount"), 6);
        compare(BarProfileModel.elementOption(tooLittle, "cava", "barWidth"), 1);
    }

    function test_cavaDrawsOnlyTheThemesNamedColors() {
        compare(BarProfileModel.elementOptionLimits.cava.color.choices,
            ["accent", "blue", "green", "yellow", "orange", "red", "purple", "text"]);

        const barElements = BarProfileModel.normalizeBarElements({
            right: [{ id: "cava", enabled: true, options: { color: "#ff0000" } }]
        });
        compare(BarProfileModel.elementOption(barElements, "cava", "color"), "blue");
        compare(BarProfileModel.elementOption(BarProfileModel.setElementOption(barElements,
            "cava", "color", "purple"), "cava", "color"), "purple");
    }

    function test_settingANumberOptionKeepsItWithinItsRange() {
        const barElements = BarProfileModel.normalizeBarElements({});
        function set(value) {
            return BarProfileModel.elementOption(BarProfileModel.setElementOption(barElements,
                "cava", "barCount", value), "cava", "barCount");
        }

        compare(set(40), 32);
        compare(set(2), 6);
        compare(set(20.4), 20);
    }

    function test_settingAChoiceOptionToAValueItDoesntListKeepsTheCurrentOne() {
        const red = BarProfileModel.setElementOption(BarProfileModel.normalizeBarElements({}),
            "cava", "color", "red");

        compare(BarProfileModel.elementOption(BarProfileModel.setElementOption(red, "cava", "color",
            "#00ff00"), "cava", "color"), "red");
    }

    // How the Bar section edits each option: a switch, a number in a range or
    // a choice among labelled values.
    function test_eachOptionSaysHowItIsEdited() {
        compare(BarProfileModel.elementOptionField("audio", "meterVisible"), { kind: "switch" });
        compare(BarProfileModel.elementOptionField("cava", "barCount"), { kind: "number", from: 6, to: 32 });
        compare(BarProfileModel.elementOptionField("cava", "barWidth"), { kind: "number", from: 1, to: 8 });

        const color = BarProfileModel.elementOptionField("cava", "color");
        compare(color.kind, "choice");
        compare(color.choices.slice(0, 2), [{ label: "Accent", value: "accent" }, { label: "Blue", value: "blue" }]);
        compare(color.choices.map(choice => choice.value),
            ["accent", "blue", "green", "yellow", "orange", "red", "purple", "text"]);
    }

    function test_changingAnElementOptionIsAPendingChange() {
        const state = fixtures.startedBarState();
        const barElements = BarProfileModel.editedProfile(state).barElements;

        const after = fixtures.edited(state, { barElements: BarProfileModel.setElementOption(
            barElements, "audio", "meterVisible", true) });

        verify(BarProfileModel.isModified(after));
    }

    function test_cavasOptionsArePendingChangesUntilSavedOrDiscarded() {
        const state = fixtures.startedBarState();
        const name = state.editingBarProfile;
        const barElements = BarProfileModel.editedProfile(state).barElements;

        const after = fixtures.edited(state, { barElements: BarProfileModel.setElementOption(
            BarProfileModel.setElementOption(barElements, "cava", "barCount", 20),
            "cava", "color", "red") });
        const drawn = BarProfileModel.profileValue(after, name, "barElements");

        verify(BarProfileModel.isModified(after));
        compare(BarProfileModel.elementOption(drawn, "cava", "barCount"), 20);
        compare(BarProfileModel.elementOption(drawn, "cava", "color"), "red");

        const discarded = fixtures.withChanges(after, BarProfileModel.discardChanges(after));
        compare(BarProfileModel.elementOption(BarProfileModel.profileValue(discarded, name,
            "barElements"), "cava", "barCount"), 12);

        const saved = fixtures.withChanges(after, BarProfileModel.saveProfile(after));
        compare(BarProfileModel.elementOption(BarProfileModel.savedProfile(saved, name).barElements,
            "cava", "barCount"), 20);
    }
}
