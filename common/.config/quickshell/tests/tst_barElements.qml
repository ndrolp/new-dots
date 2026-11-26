import QtQuick
import QtTest
import "../config/BarProfileModel.js" as BarProfileModel
import "../config/SchemaMigrations.js" as SchemaMigrations
import "../components/bar/BarElementItems.js" as BarElementItems

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

        compare(zone(normalized, "left"), ["clock", "pomodoro"]);
        compare(zone(normalized, "center"), []);
        compare(zone(normalized, "right"), ["arch", "systemMonitor", "currentApp", "-appMenu", "workspaces",
            "notifications", "recording", "privacy", "keepAwake", "media", "-cava", "audio", "bluetooth",
            "tray", "network", "battery"]);
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

        compare(element(minimal.barElements, "audio").options.meterVisible, false);
        compare(element(minimal.barElements, "battery").options.textVisible, true);
        compare(element(minimal.barElements, "battery").options.restTextVisible, true);
        verify(!("percentageVisible" in element(minimal.barElements, "battery").options));
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

        compare(BarProfileModel.elementOption(barElements, "battery", "textVisible"), true);
        compare(BarProfileModel.elementOption(barElements, "workspaces", "hideEmpty"), false);
    }

    function test_settingAnElementOptionOnlyChangesThatElement() {
        const barElements = BarProfileModel.editedProfile(fixtures.startedBarState()).barElements;

        const updated = BarProfileModel.setElementOption(barElements, "battery",
            "textVisible", false);

        compare(BarProfileModel.elementOption(updated, "battery", "textVisible"), false);
        compare(BarProfileModel.elementOption(barElements, "battery", "textVisible"), true);
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

    function test_theAppMenuIsInEveryDefaultProfileDisabledAfterCurrentApp() {
        const profiles = BarProfileModel.defaultBarProfiles();

        for (const name in profiles) {
            const barElements = profiles[name].barElements;
            const zoneName = BarProfileModel.elementZone(barElements, "currentApp");
            const ids = zone(barElements, zoneName).map(id => id.replace("-", ""));
            compare(ids.indexOf("appMenu"), ids.indexOf("currentApp") + 1, name);
            compare(BarProfileModel.elementEnabled(barElements, "appMenu"), false, name);
        }
    }

    function test_aProfileSavedBeforeTheAppMenuExistedShowsItDisabled() {
        const state = fixtures.startedBarState();

        for (const name in state.barProfiles) {
            const barElements = BarProfileModel.savedProfile(state, name).barElements;
            const zoneName = BarProfileModel.elementZone(barElements, "currentApp");
            const ids = zone(barElements, zoneName).map(id => id.replace("-", ""));
            compare(ids.indexOf("appMenu"), ids.indexOf("currentApp") + 1, name);
            compare(BarProfileModel.elementEnabled(barElements, "appMenu"), false, name);
        }
    }

    function test_aProfileThatListsTheAppMenuKeepsItEnabled() {
        const barElements = BarProfileModel.normalizeBarElements({
            center: [{ id: "appMenu", enabled: true }]
        });

        compare(BarProfileModel.elementZone(barElements, "appMenu"), "center");
        compare(BarProfileModel.elementEnabled(barElements, "appMenu"), true);
    }

    function test_theAppMenuOpensItsOwnPopup() {
        compare(BarElementItems.popupElement("appMenu"), "appMenu");
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

    // The recording indicator, then the privacy indicator, then keep-awake.
    function test_keepAwakeIsInEveryDefaultProfileEnabledAfterTheRecordingAndPrivacyIndicators() {
        const profiles = BarProfileModel.defaultBarProfiles();

        for (const name in profiles) {
            const barElements = profiles[name].barElements;
            const zoneName = BarProfileModel.elementZone(barElements, "recording");
            const ids = zone(barElements, zoneName).map(id => id.replace("-", ""));
            compare(ids.indexOf("privacy"), ids.indexOf("recording") + 1, name);
            compare(ids.indexOf("keepAwake"), ids.indexOf("recording") + 2, name);
            compare(BarProfileModel.elementEnabled(barElements, "privacy"), true, name);
            compare(BarProfileModel.elementEnabled(barElements, "keepAwake"), true, name);
        }
    }

    function test_aProfileWithoutKeepAwakeOrPrivacyGetsThemEnabledAfterTheRecordingIndicator() {
        const barElements = BarProfileModel.normalizeBarElements({
            center: [{ id: "recording", enabled: true }, { id: "clock", enabled: true }]
        });

        compare(zone(barElements, "center").slice(0, 3), ["recording", "privacy", "keepAwake"]);
        compare(BarProfileModel.elementEnabled(barElements, "privacy"), true);
        compare(BarProfileModel.elementEnabled(barElements, "keepAwake"), true);
    }

    function test_thePomodoroIsInEveryDefaultProfileRightAfterTheClock() {
        const profiles = BarProfileModel.defaultBarProfiles();

        for (const name in profiles) {
            const barElements = profiles[name].barElements;
            const zoneName = BarProfileModel.elementZone(barElements, "clock");
            const ids = zone(barElements, zoneName).map(id => id.replace("-", ""));
            compare(ids.indexOf("pomodoro"), ids.indexOf("clock") + 1, name);
            compare(BarProfileModel.elementEnabled(barElements, "pomodoro"), true, name);
        }
    }

    // What there is to show when nothing is going on: no player, battery,
    // recording or sound, keep-awake off and no pomodoro started.
    function nothingGoingOn(values) {
        return Object.assign({ live: [], expanded: false, player: null, recordings: [], hasBattery: false,
            cavaSilent: true, keepAwakeOn: false, pomodoroStarted: false,
            captures: { microphone: [], camera: [] } }, values);
    }

    // The pomodoro shows its countdown only while one is started, running
    // or paused, on every bar style.
    function test_thePomodoroShowsOnlyWhileStarted_data() {
        return [
            { tag: "started", status: { pomodoroStarted: true }, shown: true },
            { tag: "not started", status: {}, shown: false },
            { tag: "started, capsule expanded", status: { pomodoroStarted: true, expanded: true }, shown: true },
            { tag: "not started, capsule expanded", status: { expanded: true }, shown: false }
        ];
    }

    function test_thePomodoroShowsOnlyWhileStarted(data) {
        const barElements = BarProfileModel.normalizeBarElements(minimalElements());

        compare(BarElementItems.itemVisible("pomodoro", barElements, nothingGoingOn(data.status)), data.shown);
    }

    function test_aDisabledPomodoroStaysHiddenWhileStarted() {
        const barElements = BarProfileModel.setElementEnabled(
            BarProfileModel.normalizeBarElements(minimalElements()), "pomodoro", false);

        compare(BarElementItems.itemVisible("pomodoro", barElements,
            nothingGoingOn({ pomodoroStarted: true })), false);
    }

    // Keep-awake has something to show while off too, the outline cup that
    // opens its popup, so nothing else going on hides it.
    function test_keepAwakeIsShownWhileOff() {
        const barElements = BarProfileModel.normalizeBarElements(minimalElements());

        compare(BarElementItems.itemVisible("keepAwake", barElements, nothingGoingOn()), true);
    }

    // The bar elements that can be live, enabled, on any other bar style, or
    // in a capsule's row: media while any player exists, playing or not,
    // the recording indicator while recording, keep-awake on or off.
    function test_theElementsThatCanBeLiveShowAsOnAnyBar_data() {
        return [
            { tag: "media paused", element: "media", status: { player: { isPlaying: false } }, shown: true },
            { tag: "media playing", element: "media", status: { player: { isPlaying: true } }, shown: true },
            { tag: "no player", element: "media", status: {}, shown: false },
            { tag: "recording", element: "recording", status: { recordings: [{ app: "obs" }] }, shown: true },
            { tag: "not recording", element: "recording", status: {}, shown: false },
            { tag: "keep-awake off", element: "keepAwake", status: {}, shown: true },
            { tag: "keep-awake on", element: "keepAwake", status: { keepAwakeOn: true }, shown: true },
            { tag: "microphone in use", element: "privacy",
                status: { captures: { microphone: ["Discord"], camera: [] } }, shown: true },
            { tag: "camera in use", element: "privacy",
                status: { captures: { microphone: [], camera: ["obs"] } }, shown: true },
            { tag: "nothing captured", element: "privacy", status: {}, shown: false },
            { tag: "nothing captured, expanded", element: "privacy", status: { expanded: true }, shown: false }
        ];
    }

    function test_theElementsThatCanBeLiveShowAsOnAnyBar(data) {
        const barElements = { left: [], right: [], center: [{ id: "recording", enabled: true },
            { id: "media", enabled: true }, { id: "keepAwake", enabled: true }, { id: "privacy", enabled: true }] };

        compare(BarElementItems.itemVisible(data.element, barElements, nothingGoingOn(data.status)), data.shown);
    }

    // A capsule's row lists its live elements switched off, but a collapsed
    // capsule shows them beside its workspace pills while they are active:
    // media while a track plays, the recording indicator while recording,
    // keep-awake while on. Expanded, they show as on any other bar style.
    function test_aLiveElementShowsCollapsedOnlyWhileActive_data() {
        const playing = { isPlaying: true };
        const paused = { isPlaying: false };
        return [
            { tag: "recording", element: "recording", status: { recordings: [{ app: "obs" }] }, shown: true },
            { tag: "not recording", element: "recording", status: {}, shown: false },
            { tag: "not recording, expanded", element: "recording", status: { expanded: true }, shown: false },
            { tag: "media playing", element: "media", status: { player: playing }, shown: true },
            { tag: "media paused", element: "media", status: { player: paused }, shown: false },
            { tag: "media paused, expanded", element: "media", status: { player: paused, expanded: true },
                shown: true },
            { tag: "no player, expanded", element: "media", status: { expanded: true }, shown: false },
            { tag: "keep-awake on", element: "keepAwake", status: { keepAwakeOn: true }, shown: true },
            { tag: "keep-awake off", element: "keepAwake", status: {}, shown: false },
            { tag: "keep-awake off, expanded", element: "keepAwake", status: { expanded: true }, shown: true },
            { tag: "pomodoro running or paused", element: "pomodoro", status: { pomodoroStarted: true },
                shown: true },
            { tag: "pomodoro cancelled or completed", element: "pomodoro", status: {}, shown: false },
            { tag: "pomodoro not started, expanded", element: "pomodoro", status: { expanded: true },
                shown: false },
            { tag: "microphone and camera in use", element: "privacy",
                status: { captures: { microphone: ["Firefox"], camera: ["Firefox"] } }, shown: true },
            { tag: "nothing captured", element: "privacy", status: {}, shown: false },
            { tag: "nothing captured, expanded", element: "privacy", status: { expanded: true }, shown: false }
        ];
    }

    function test_aLiveElementShowsCollapsedOnlyWhileActive(data) {
        const barElements = { left: [], right: [], center: [{ id: "recording", enabled: false },
            { id: "media", enabled: false }, { id: "keepAwake", enabled: false },
            { id: "pomodoro", enabled: false }, { id: "privacy", enabled: false }] };
        const status = nothingGoingOn(Object.assign({ live: ["recording", "media", "keepAwake", "pomodoro",
            "privacy"] },
            data.status));

        compare(BarElementItems.itemVisible(data.element, barElements, status), data.shown);
    }

    // While the capsule glance shows a live element's card (`glance`,
    // CapsuleGlance.leavingElements), it leaves its place beside the pills,
    // and comes back once the glance goes; the other live elements stay.
    function test_aLiveElementLeavesWhileItsCardShows_data() {
        const playing = { isPlaying: true };
        return [
            { tag: "media's card shows", element: "media", status: { player: playing, glance: ["media"] },
                shown: false },
            { tag: "no glance", element: "media", status: { player: playing, glance: [] }, shown: true },
            { tag: "another's card", element: "keepAwake", status: { keepAwakeOn: true, glance: ["media"] },
                shown: true }
        ];
    }

    function test_aLiveElementLeavesWhileItsCardShows(data) {
        const barElements = { left: [], right: [], center: [{ id: "media", enabled: false },
            { id: "keepAwake", enabled: false }] };
        const status = nothingGoingOn(Object.assign({ live: ["media", "keepAwake"], expanded: true },
            data.status));

        compare(BarElementItems.itemVisible(data.element, barElements, status), data.shown);
    }

    function test_keepAwakeCanBeMovedToAnotherZone() {
        const barElements = BarProfileModel.normalizeBarElements(minimalElements());

        const moved = BarProfileModel.moveElementToZone(barElements, "keepAwake", "left");

        compare(zone(moved, "left"), ["arch", "workspaces", "keepAwake"]);
        compare(BarProfileModel.elementEnabled(moved, "keepAwake"), true);
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
        compare(zone(beforeSystemMonitor, "center").slice(0, 4), ["clock", "pomodoro", "arch",
            "systemMonitor"]);
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

    // The control center is the bell's popup; the bell keeps its saved id.
    function test_theControlCenterOpensUnderTheNotificationsElement() {
        compare(BarElementItems.popupElement("controlCenter"), "notifications");
    }

    function test_aPopupNamedAfterItsElementOpensUnderIt() {
        compare(BarElementItems.popupElement("battery"), "battery");
        compare(BarElementItems.popupElement("pomodoro"), "clock");
    }

    function test_someBarElementsOpenNoPopup() {
        for (const element of ["arch", "workspaces", "currentApp", "recording", "cava"])
            verify(!BarElementItems.opensPopup(element), element);
    }

    function test_everyOtherBarElementOpensAPopup() {
        for (const element of ["systemMonitor", "appMenu", "notifications", "keepAwake", "media",
            "audio", "bluetooth", "tray", "network", "battery", "clock", "pomodoro", "privacy"])
            verify(BarElementItems.opensPopup(element), element);
    }

    // The privacy indicator opens its own popup, listing the apps that use
    // the microphone or a camera.
    function test_thePrivacyIndicatorOpensItsOwnPopup() {
        verify(BarElementItems.opensPopup("privacy"));
        compare(BarElementItems.popupElement("privacy"), "privacy");
    }

    // The pomodoro opens the popup it is controlled from, which a pomodoro is
    // started from through the clock, so it opens under the clock.
    function test_thePomodoroOpensThePopupItIsControlledFrom() {
        verify(BarElementItems.opensPopup("pomodoro"));
        compare(BarElementItems.popupElement("pomodoro"), "clock");
    }

    function test_workspacesHaveARadiusOption() {
        compare(BarProfileModel.elementOptionField("workspaces", "radius"),
            { kind: "number", from: 0, to: 24 });
    }

    function test_migratingGivesWorkspacesTheRadiusTheyFollowed() {
        const barElements = BarProfileModel.defaultBarElements([]);
        const version10 = { schemaVersion: 10, barProfiles: {
            work: { radius: 6, barElements: barElements },
            media: { radius: 14, barElements: barElements }
        } };
        const profiles = SchemaMigrations.migrate(version10, {}).appearance.barProfiles;

        compare(BarProfileModel.elementOption(profiles.work.barElements, "workspaces", "radius"), 6);
        compare(BarProfileModel.elementOption(profiles.media.barElements, "workspaces", "radius"), 14);
    }

    function test_aNewProfilesWorkspacesFollowItsRadius() {
        const profiles = BarProfileModel.defaultBarProfiles();

        for (const name in profiles) {
            compare(BarProfileModel.elementOption(profiles[name].barElements, "workspaces", "radius"),
                profiles[name].radius, name);
        }
    }

    function test_migratingSplitsTheTransparentBarBorderIntoThreeBorders() {
        const version11 = { schemaVersion: 11, barProfiles: {
            work: { barTransparentBorder: false },
            media: { barTransparentBorder: true },
            presentation: {}
        } };
        const profiles = SchemaMigrations.migrate(version11, {}).appearance.barProfiles;

        compare(profiles.work.barBorder, false);
        compare(profiles.work.elementBorder, false);
        compare(profiles.work.groupBorder, false);
        compare(profiles.media.barBorder, true);
        compare(profiles.media.elementBorder, true);
        compare(profiles.media.groupBorder, true);
        verify(profiles.media.barTransparentBorder === undefined);
        verify(profiles.presentation.barBorder === undefined);
    }

    function test_workspacesHaveAVerticalPaddingOption() {
        compare(BarProfileModel.elementOptionField("workspaces", "verticalPadding"),
            { kind: "number", from: 0, to: 16 });
    }

    function test_migratingGivesWorkspacesTheVerticalPaddingTheyFollowed() {
        const barElements = BarProfileModel.defaultBarElements([]);
        const version12 = { schemaVersion: 12, barProfiles: {
            work: { barTransparent: false, elementVerticalPadding: 7, pillVerticalPadding: 2,
                barElements: barElements },
            media: { barTransparent: true, elementVerticalPadding: 7, pillVerticalPadding: 2,
                barElements: barElements }
        } };
        const profiles = SchemaMigrations.migrate(version12, {}).appearance.barProfiles;

        compare(BarProfileModel.elementOption(profiles.work.barElements, "workspaces", "verticalPadding"), 7);
        compare(BarProfileModel.elementOption(profiles.media.barElements, "workspaces", "verticalPadding"), 4);
    }

    function test_aNewProfilesWorkspacesKeepTheVerticalPaddingTheyFollowed() {
        const profiles = BarProfileModel.defaultBarProfiles();

        for (const name in profiles) {
            const profile = BarProfileModel.completeProfile(profiles[name]);
            compare(BarProfileModel.elementOption(profile.barElements, "workspaces", "verticalPadding"),
                profile.barStyle !== "opaque" ? profile.pillVerticalPadding + 2 : profile.elementVerticalPadding,
                name);
        }
    }

    function test_migratingGivesIconsTheTextSizeTheyFollowed() {
        const version13 = { schemaVersion: 13, barProfiles: {
            work: { textSize: 13 },
            media: { textSize: 15, iconSize: 18 },
            presentation: {}
        } };
        const profiles = SchemaMigrations.migrate(version13, {}).appearance.barProfiles;

        compare(profiles.work.iconSize, 13);
        compare(profiles.media.iconSize, 18);
        verify(profiles.presentation.iconSize === undefined);
    }

    function test_aNewProfilesIconsStartAtItsTextSize() {
        const profiles = BarProfileModel.defaultBarProfiles();

        for (const name in profiles) {
            const profile = BarProfileModel.completeProfile(profiles[name]);
            compare(profile.iconSize, profile.textSize, name);
        }
    }

    function test_migratingGivesGroupsThePaddingTheyFollowed() {
        const version14 = { schemaVersion: 14, barProfiles: {
            work: { spacing: 6 },
            media: { spacing: 4, groupHorizontalPadding: 9 }
        } };
        const profiles = SchemaMigrations.migrate(version14, {}).appearance.barProfiles;

        compare(profiles.work.groupHorizontalPadding, 6);
        compare(profiles.media.groupHorizontalPadding, 9);
        compare(BarProfileModel.completeProfile(profiles.work).groupVerticalPadding, 0);
    }

    function test_aNewProfilesGroupsKeepThePaddingTheyFollowed() {
        const profiles = BarProfileModel.defaultBarProfiles();

        for (const name in profiles) {
            const profile = BarProfileModel.completeProfile(profiles[name]);
            compare(profile.groupHorizontalPadding, profile.spacing, name);
            compare(profile.groupVerticalPadding, 0, name);
        }
    }

    // A profile of schema version 18, whose clock still showed the pomodoro,
    // brought to the current schema.
    function migratedFromVersion18(profile) {
        return SchemaMigrations.migrate({ schemaVersion: 18, barProfiles: { saved: profile } }, {})
            .appearance.barProfiles.saved;
    }

    // A zone as ids in order, an element that joins the previous one
    // prefixed with "+", a disabled one with "-".
    function groupedZone(barElements, zoneName) {
        return barElements[zoneName].map(element =>
            (element.joinPrevious ? "+" : "") + (element.enabled ? "" : "-") + element.id);
    }

    function test_migratingPutsThePomodoroRightAfterTheClock() {
        const profile = migratedFromVersion18({ barElements: { left: [], center: [], right: [
            { id: "battery", enabled: true }, { id: "clock", enabled: true },
            { id: "notifications", enabled: true }
        ] } });

        compare(groupedZone(profile.barElements, "right"), ["battery", "clock", "pomodoro", "notifications"]);
    }

    // In the clock's group, wherever the clock sits in it, the pomodoro
    // stays in it; outside one it joins nothing.
    function test_migratingPutsThePomodoroInTheClocksGroup_data() {
        const battery = { id: "battery", enabled: true };
        const notifications = { id: "notifications", enabled: true };
        return [
            { tag: "last of its group", right: [battery, { id: "clock", enabled: true, joinPrevious: true },
                notifications], zone: ["battery", "+clock", "+pomodoro", "notifications"] },
            { tag: "first of its group", right: [battery, { id: "clock", enabled: true },
                { id: "notifications", enabled: true, joinPrevious: true }],
                zone: ["battery", "clock", "+pomodoro", "+notifications"] },
            { tag: "alone, last of its zone", right: [battery, { id: "clock", enabled: true }],
                zone: ["battery", "clock", "pomodoro"] }
        ];
    }

    function test_migratingPutsThePomodoroInTheClocksGroup(data) {
        const profile = migratedFromVersion18({ barElements: { left: [], center: [], right: data.right } });

        compare(groupedZone(profile.barElements, "right"), data.zone);
    }

    // A profile that already lists the pomodoro, in the clock's zone or
    // another, keeps it where it is and gets no second one.
    function test_migratingKeepsAPomodoroAlreadyThere_data() {
        return [
            { tag: "beside the clock", left: [], right: [{ id: "clock", enabled: true },
                { id: "pomodoro", enabled: false }], zone: ["clock", "-pomodoro"], leftZone: [] },
            { tag: "in another zone", left: [{ id: "pomodoro", enabled: true }],
                right: [{ id: "clock", enabled: true }], zone: ["clock"], leftZone: ["pomodoro"] }
        ];
    }

    function test_migratingKeepsAPomodoroAlreadyThere(data) {
        const profile = migratedFromVersion18({ barElements: { left: data.left, center: [], right: data.right } });

        compare(groupedZone(profile.barElements, "right"), data.zone);
        compare(groupedZone(profile.barElements, "left"), data.leftZone);
    }

    // A clock that was off showed no countdown either.
    function test_migratingTurnsThePomodoroOffWithTheClock() {
        const profile = migratedFromVersion18({ barElements: { left: [{ id: "clock", enabled: false }],
            center: [], right: [] } });

        compare(groupedZone(profile.barElements, "left"), ["-clock", "-pomodoro"]);
    }

    // A profile of schema version 20, before the pomodoro could be live,
    // brought to the current schema.
    function migratedFromVersion20(profile) {
        return SchemaMigrations.migrate({ schemaVersion: 20, barProfiles: { saved: profile } }, {})
            .appearance.barProfiles.saved;
    }

    // A migrated capsule shows the pomodoro live right of the workspace
    // pills, wherever it showed the clock; the other places stay.
    function test_migratingPlacesThePomodoroLiveRight_data() {
        return [
            { tag: "clock shown, from version 18", place: "shown", migrate: migratedFromVersion18 },
            { tag: "clock hidden, from version 18", place: "hidden", migrate: migratedFromVersion18 },
            { tag: "pomodoro shown, from version 20", place: "shown", migrate: migratedFromVersion20 },
            { tag: "pomodoro hidden, from version 20", place: "hidden", migrate: migratedFromVersion20 }
        ];
    }

    function test_migratingPlacesThePomodoroLiveRight(data) {
        const profile = data.migrate({ barStyle: "capsule",
            capsulePlaces: { clock: data.place, pomodoro: data.place, recording: "liveRight", battery: "shown" } });

        compare(profile.capsulePlaces.pomodoro, "liveRight");
        compare(profile.capsulePlaces.clock, data.place);
        compare(profile.capsulePlaces.recording, "liveRight");
        compare(profile.capsulePlaces.battery, "shown");
    }

    // A profile that saved no places, or no bar elements, takes the defaults
    // when it loads, which already place the pomodoro beside the clock and
    // live right in a capsule.
    function test_migratingLeavesAProfileWithoutPlacesOrElementsToTheDefaults_data() {
        return [
            { tag: "from version 18", migrate: migratedFromVersion18 },
            { tag: "from version 20", migrate: migratedFromVersion20 }
        ];
    }

    function test_migratingLeavesAProfileWithoutPlacesOrElementsToTheDefaults(data) {
        const profile = data.migrate({ barStyle: "capsule" });

        compare(profile.capsulePlaces, undefined);
        compare(profile.barElements, undefined);
    }

    // A migrated default capsule shows, right of the pills from them
    // outward, the recording indicator then the pomodoro.
    function test_aMigratedCapsuleShowsThePomodoroAfterTheRecordingIndicator() {
        const profile = migratedFromVersion18({ barStyle: "capsule",
            barElements: { left: [], center: [{ id: "workspaces", enabled: true }], right: [
                { id: "recording", enabled: true }, { id: "clock", enabled: true }] },
            capsulePlaces: { clock: "shown", recording: "liveRight" } });

        compare(BarProfileModel.capsulePlaceIds(profile.barElements, profile.capsulePlaces).live.right,
            ["recording", "privacy", "pomodoro"]);
    }

    // A profile of schema version 21, before the privacy indicator, brought
    // to the current schema.
    function migratedFromVersion21(profile) {
        return SchemaMigrations.migrate({ schemaVersion: 21, barProfiles: { saved: profile } }, {})
            .appearance.barProfiles.saved;
    }

    // The privacy indicator goes right after the recording indicator, in
    // its group if it is in one, and on if the recording indicator is.
    function test_migratingPutsThePrivacyIndicatorRightAfterTheRecordingIndicator_data() {
        const notifications = { id: "notifications", enabled: true };
        const keepAwake = { id: "keepAwake", enabled: true };
        return [
            { tag: "alone", right: [notifications, { id: "recording", enabled: true }, keepAwake],
                zone: ["notifications", "recording", "privacy", "keepAwake"] },
            { tag: "last of its group", right: [notifications,
                { id: "recording", enabled: true, joinPrevious: true }, keepAwake],
                zone: ["notifications", "+recording", "+privacy", "keepAwake"] },
            { tag: "first of its group", right: [notifications, { id: "recording", enabled: true },
                { id: "keepAwake", enabled: true, joinPrevious: true }],
                zone: ["notifications", "recording", "+privacy", "+keepAwake"] },
            { tag: "off", right: [notifications, { id: "recording", enabled: false }],
                zone: ["notifications", "-recording", "-privacy"] }
        ];
    }

    function test_migratingPutsThePrivacyIndicatorRightAfterTheRecordingIndicator(data) {
        const profile = migratedFromVersion21({ barElements: { left: [], center: [], right: data.right } });

        compare(groupedZone(profile.barElements, "right"), data.zone);
    }

    // A profile that already lists the privacy indicator, in the recording
    // indicator's zone or another, keeps it where it is and gets no second
    // one.
    function test_migratingKeepsAPrivacyIndicatorAlreadyThere_data() {
        return [
            { tag: "beside the recording indicator", left: [], right: [{ id: "recording", enabled: true },
                { id: "privacy", enabled: false }], zone: ["recording", "-privacy"], leftZone: [] },
            { tag: "in another zone", left: [{ id: "privacy", enabled: true }],
                right: [{ id: "recording", enabled: true }], zone: ["recording"], leftZone: ["privacy"] }
        ];
    }

    function test_migratingKeepsAPrivacyIndicatorAlreadyThere(data) {
        const profile = migratedFromVersion21({ barElements: { left: data.left, center: [], right: data.right } });

        compare(groupedZone(profile.barElements, "right"), data.zone);
        compare(groupedZone(profile.barElements, "left"), data.leftZone);
    }

    // A migrated capsule shows it live right, between the recording
    // indicator and the pomodoro; the other places stay.
    function test_migratingPlacesThePrivacyIndicatorLiveRightBetweenRecordingAndPomodoro() {
        const profile = migratedFromVersion21({ barStyle: "capsule",
            barElements: { left: [], center: [{ id: "workspaces", enabled: true }], right: [
                { id: "recording", enabled: true }, { id: "clock", enabled: true },
                { id: "pomodoro", enabled: true }] },
            capsulePlaces: { recording: "liveRight", clock: "shown", pomodoro: "liveRight", battery: "hidden" } });

        compare(profile.capsulePlaces.privacy, "liveRight");
        compare(profile.capsulePlaces.clock, "shown");
        compare(profile.capsulePlaces.battery, "hidden");
        compare(BarProfileModel.capsulePlaceIds(profile.barElements, profile.capsulePlaces).live.right,
            ["recording", "privacy", "pomodoro"]);
    }

    // A profile that saved no places, or no bar elements, takes the
    // defaults when it loads, which already place it there.
    function test_migratingLeavesAProfileWithoutPlacesOrElementsToTheDefaultsForPrivacy() {
        const profile = migratedFromVersion21({ barStyle: "capsule" });

        compare(profile.capsulePlaces, undefined);
        compare(profile.barElements, undefined);
        compare(BarProfileModel.completeProfile(profile).capsulePlaces.privacy, "liveRight");
    }
}
