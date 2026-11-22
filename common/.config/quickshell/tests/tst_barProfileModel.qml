import QtQuick
import QtTest
import "../config/BarProfileModel.js" as BarProfileModel
import "../config/SchemaMigrations.js" as SchemaMigrations

TestCase {
    name: "BarProfileModel"

    Fixtures {
        id: fixtures
    }

    // A bar profile is shown by its name with a capital first letter.
    // Switching needs no migration: nothing but the position changes, and an
    // element stays in the zone it was saved in.
    function test_switchingPositionMovesNoElementBetweenZones_data() {
        return ["bottom", "left", "right", "top"].map(position => ({ tag: position, position: position }));
    }

    function test_switchingPositionMovesNoElementBetweenZones(data) {
        const started = fixtures.startedBarState();
        const before = BarProfileModel.editedProfile(started);
        const after = BarProfileModel.editedProfile(fixtures.edited(started, { barPosition: data.position }));

        compare(after.barPosition, data.position);
        compare(JSON.stringify(after.barElements), JSON.stringify(before.barElements));
        compare(JSON.stringify(Object.assign({}, after, { barPosition: before.barPosition })),
            JSON.stringify(before));
    }

    function test_aProfileIsShownCapitalised() {
        compare(BarProfileModel.profileDisplayName("presentation"), "Presentation");
        compare(BarProfileModel.profileDisplayName(""), "");
    }

    // Choosing a bar profile offers every profile, in name order.
    function test_profileChoicesAreSortedByName() {
        compare(BarProfileModel.profileChoices({ minimal: {}, laptop: {}, presentation: {} }), [
            { label: "Laptop", value: "laptop" },
            { label: "Minimal", value: "minimal" },
            { label: "Presentation", value: "presentation" }
        ]);
        compare(BarProfileModel.profileChoices(undefined), []);
    }

    // The profile keybinds pick by position in that same order, so a renamed
    // profile keeps a keybind.
    function test_profileAtCountsFromOneInNameOrder() {
        const profiles = { minimal: {}, laptop: {}, presentation: {} };

        compare(BarProfileModel.profileAt(profiles, 1), "laptop");
        compare(BarProfileModel.profileAt(profiles, 3), "presentation");
        compare(BarProfileModel.profileAt(profiles, 0), "");
        compare(BarProfileModel.profileAt(profiles, 4), "");
        compare(BarProfileModel.profileAt(undefined, 1), "");
    }

    function test_editingAProfileShowsItsSavedValues() {
        const state = fixtures.startedBarState();

        const after = fixtures.withChanges(state, BarProfileModel.editProfile(state, "presentation"));

        const edited = BarProfileModel.editedProfile(after);
        compare(edited.barHeight, 30);
        compare(edited.horizontalPadding, 12);
        compare(edited.barStyle, "docked");
        compare(edited.transparentBarTopMargin, 8);
    }

    function test_theEditedProfileDoesNotShareObjectsWithTheSavedProfile() {
        const state = fixtures.startedBarState();

        const edited = BarProfileModel.editedProfile(state);
        const workspaces = [].concat(edited.barElements.left, edited.barElements.center,
            edited.barElements.right).find(element => element.id === "workspaces");
        workspaces.options.glyphs[0] = "x";
        edited.barHeight = 99;

        compare(BarProfileModel.elementOption(BarProfileModel.editedProfile(state).barElements,
            "workspaces", "glyphs")[0], "");
        compare(state.barProfiles.minimal.barHeight, 34);
    }

    function test_savingStoresOnlyBarSettings() {
        const state = fixtures.edited(fixtures.startedBarState(), { barHeight: 41 });

        const changes = BarProfileModel.saveProfile(state);

        compare(changes.barProfiles.minimal.barHeight, 41);
        verify(!("doNotDisturb" in changes.barProfiles.minimal));
        compare(changes.barProfiles.media.barHeight, 34);
    }

    function test_settingsOtherThanBarSettingsAreNotPendingChanges() {
        const state = fixtures.startedBarState();

        verify(!BarProfileModel.isModified(fixtures.edited(state, { doNotDisturb: true })));
    }

    function test_readingTheEditedProfileReturnsThePendingValue() {
        const state = fixtures.edited(fixtures.startedBarState(), { barHeight: 41 });

        compare(BarProfileModel.profileValue(state, "minimal", "barHeight"), 41);
    }

    function test_readingAProfileNotBeingEditedReturnsItsSavedValue() {
        const state = fixtures.edited(fixtures.startedBarState(), { barHeight: 41 });

        compare(BarProfileModel.profileValue(state, "presentation", "barHeight"), 30);
    }

    function test_readingAnUnknownProfileReturnsTheDefaults() {
        const state = fixtures.startedBarState();

        compare(BarProfileModel.profileValue(state, "missing", "barHeight"),
            BarProfileModel.defaultProfile.barHeight);
    }

    // A profile saved before Bar position existed has no such key.
    function test_aProfileSavedWithoutABarPositionIsATopBar() {
        const state = fixtures.startedBarState();
        delete state.barProfiles.presentation.barPosition;

        compare(BarProfileModel.savedProfile(state, "presentation").barPosition, "top");
        compare(BarProfileModel.profileValue(state, "presentation", "barPosition"), "top");
    }

    function test_everyDefaultProfileIsATopBar() {
        const profiles = BarProfileModel.defaultBarProfiles();

        for (const name in profiles)
            compare(profiles[name].barPosition, "top", name);
    }

    function test_anUnknownBarPositionLoadsAsTop() {
        compare(BarProfileModel.completeProfile({ barPosition: "middle" }).barPosition, "top");
    }

    function test_anUnknownBarStyleLoadsAsOpaque() {
        compare(BarProfileModel.completeProfile({ barStyle: "glass" }).barStyle, "opaque");
    }

    function test_everyBarStyleIsKeptAsSaved_data() {
        return ["opaque", "transparent", "docked", "capsule"].map(style => ({ tag: style, style: style }));
    }

    function test_everyBarStyleIsKeptAsSaved(data) {
        compare(BarProfileModel.completeProfile({ barStyle: data.style }).barStyle, data.style);
    }

    // Each bar style has a name to ask a profile whether it is that style.
    function test_eachBarStyleIsAskedForByName_data() {
        return [
            { tag: "opaque", style: "opaque", answers: [true, false, false, false] },
            { tag: "transparent", style: "transparent", answers: [false, true, false, false] },
            { tag: "docked", style: "docked", answers: [false, false, true, false] },
            { tag: "capsule", style: "capsule", answers: [false, false, false, true] }
        ];
    }

    function test_eachBarStyleIsAskedForByName(data) {
        const bar = { barStyle: data.style };

        compare([BarProfileModel.opaque(bar), BarProfileModel.transparent(bar),
            BarProfileModel.docked(bar), BarProfileModel.capsule(bar)], data.answers);
    }

    function test_theOldBarStyleSwitchesAreNotKept() {
        const profile = BarProfileModel.completeProfile({ barTransparent: true,
            transparentBarSlanted: true });

        compare(profile.barStyle, "opaque");
        verify(!("barTransparent" in profile));
        verify(!("transparentBarSlanted" in profile));
    }

    function test_everyBarPositionIsKeptAsSaved_data() {
        return ["top", "bottom", "left", "right"].map(position => ({ tag: position, position: position }));
    }

    function test_everyBarPositionIsKeptAsSaved(data) {
        compare(BarProfileModel.completeProfile({ barPosition: data.position }).barPosition, data.position);
    }

    // A capsule sits only at the top or the bottom: on a side it moves to the top.
    function test_aCapsuleOnASideLoadsAtTheTop_data() {
        return [
            { tag: "left", position: "left", loaded: "top" },
            { tag: "right", position: "right", loaded: "top" },
            { tag: "bottom", position: "bottom", loaded: "bottom" }
        ];
    }

    function test_aCapsuleOnASideLoadsAtTheTop(data) {
        compare(BarProfileModel.completeProfile({ barStyle: "capsule", barPosition: data.position })
            .barPosition, data.loaded);
    }

    // A profile that never chose its collapsed capsule's places shows Arch,
    // the clock and the control center in the row, media live left of the
    // workspace pills and the recording indicator live right; every other
    // bar element but the workspaces is hidden.
    function test_aProfileWithoutCollapsedPlacesGetsTheDefaultOnes() {
        const places = BarProfileModel.completeProfile({ barStyle: "capsule" }).capsulePlaces;

        compare(places.arch, "shown");
        compare(places.clock, "shown");
        compare(places.notifications, "shown");
        compare(places.media, "liveLeft");
        compare(places.recording, "liveRight");
        compare(places.keepAwake, "hidden");
        compare(places.battery, "hidden");
        compare(places.workspaces, undefined);
    }

    // A new capsule shows the pomodoro live right of the workspace pills;
    // it can take every live place.
    function test_aProfileWithoutCollapsedPlacesShowsThePomodoroLiveRight() {
        const places = BarProfileModel.completeProfile({ barStyle: "capsule" }).capsulePlaces;

        compare(places.pomodoro, "liveRight");
        compare(BarProfileModel.capsulePlacesFor("pomodoro"), ["hidden", "shown", "liveLeft", "liveRight"]);
        verify(BarProfileModel.canBeLive("pomodoro"));
    }

    // A new capsule shows the privacy indicator live right of the workspace
    // pills, between the recording indicator and the pomodoro.
    function test_aProfileWithoutCollapsedPlacesShowsThePrivacyIndicatorLiveRight() {
        const profile = BarProfileModel.completeProfile({ barStyle: "capsule" });

        compare(profile.capsulePlaces.privacy, "liveRight");
        verify(BarProfileModel.canBeLive("privacy"));
        compare(BarProfileModel.capsulePlaceIds(profile.barElements, profile.capsulePlaces).live.right,
            ["recording", "privacy", "pomodoro"]);
    }

    // The elements with an icon and text show both by default, on the bar and
    // in a capsule at rest; the at-rest options apply only while resting.
    function test_anElementShowsItsIconAndTextByDefaultAndAtRestByItsOwnOptions() {
        let barElements = BarProfileModel.normalizeBarElements({ right: [{ id: "battery", enabled: true }] });

        compare(BarProfileModel.iconTextShown(barElements, "battery", false), { icon: true, text: true });
        barElements = BarProfileModel.setElementOption(barElements, "battery", "restTextVisible", false);
        compare(BarProfileModel.iconTextShown(barElements, "battery", false), { icon: true, text: true });
        compare(BarProfileModel.iconTextShown(barElements, "battery", true), { icon: true, text: false });
        barElements = BarProfileModel.setElementOption(barElements, "battery", "iconVisible", false);
        compare(BarProfileModel.iconTextShown(barElements, "battery", false), { icon: false, text: true });
    }

    // Hiding both would leave an empty element: it keeps its icon.
    function test_anElementWithIconAndTextOffKeepsItsIcon() {
        let barElements = BarProfileModel.normalizeBarElements({ right: [{ id: "clock", enabled: true }] });
        barElements = BarProfileModel.setElementOption(barElements, "clock", "iconVisible", false);
        barElements = BarProfileModel.setElementOption(barElements, "clock", "textVisible", false);

        compare(BarProfileModel.iconTextShown(barElements, "clock", false), { icon: true, text: false });
    }

    // Icon-only elements have no such options and always show their icon.
    function test_anIconOnlyElementHasNoIconOrTextOptions() {
        const barElements = BarProfileModel.normalizeBarElements({ right: [{ id: "network", enabled: true }] });

        compare(BarProfileModel.elementOptions(barElements, "network"), {});
        compare(BarProfileModel.iconTextShown(barElements, "network", true), { icon: true, text: true });
    }

    // Media's title and the battery's percentage switches become Show text,
    // on the bar and at rest, so they look as they did.
    function test_theOldTitleAndPercentageSwitchesBecomeShowText() {
        const migrated = SchemaMigrations.migrate({ schemaVersion: 17, barProfiles: { saved: {
            barElements: { left: [], center: [], right: [
                { id: "media", enabled: true, options: { titleVisible: false } },
                { id: "battery", enabled: true, options: { percentageVisible: true } }
            ] } } } }, {}).appearance.barProfiles.saved.barElements.right;

        compare(migrated[0].options, { textVisible: false, restTextVisible: false });
        compare(migrated[1].options, { textVisible: true, restTextVisible: true });
    }

    // Bar profiles of schema version 16, which listed the bar elements a
    // collapsed capsule shows, brought to the current schema.
    function migratedProfiles(profiles) {
        return SchemaMigrations.migrate({ schemaVersion: 16, barProfiles: profiles }, {})
            .appearance.barProfiles;
    }

    // A profile saved before collapsed places keeps what its collapsed
    // capsule showed: the elements its list named stay shown, media and the
    // recording indicator stay live where they were drawn, the rest hidden.
    // The list itself is dropped.
    function test_aProfileSavedWithAListOfShownElementsMigrates() {
        const profile = migratedProfiles({ saved: { barStyle: "capsule",
            capsuleElements: ["battery", "clock", "media", "workspaces"] } }).saved;

        compare(profile.capsulePlaces.battery, "shown");
        compare(profile.capsulePlaces.clock, "shown");
        compare(profile.capsulePlaces.arch, "hidden");
        compare(profile.capsulePlaces.notifications, "hidden");
        compare(profile.capsulePlaces.media, "liveLeft");
        compare(profile.capsulePlaces.recording, "liveRight");
        compare(profile.capsulePlaces.keepAwake, "hidden");
        compare(profile.capsulePlaces.workspaces, undefined);
        compare(profile.capsuleElements, undefined);
    }

    // A profile that saved no list gets the default places when it loads,
    // which are what its collapsed capsule showed without one.
    function test_aProfileSavedWithoutAListGetsTheDefaultPlaces() {
        const profile = migratedProfiles({ saved: { barStyle: "capsule" } }).saved;

        compare(profile.capsulePlaces, undefined);
        compare(BarProfileModel.completeProfile(profile).capsulePlaces, BarProfileModel.defaultCapsulePlaces);
    }

    // Once migrated, completing a profile never reads a list again.
    function test_aListLeftInAProfileIsIgnored() {
        const profile = BarProfileModel.completeProfile({ barStyle: "capsule", capsuleElements: ["battery"] });

        compare(profile.capsulePlaces, BarProfileModel.defaultCapsulePlaces);
        compare(profile.capsuleElements, undefined);
    }

    // Saved places survive completing the profile, as every read and save
    // does; a place an element can't take, or an unknown one, falls back to
    // the default and unknown elements are dropped.
    function test_savedCollapsedPlacesAreKeptWhenValid() {
        const places = BarProfileModel.completeProfile({ capsulePlaces: {
            battery: "shown", media: "liveRight", recording: "hidden", clock: "liveLeft",
            arch: "floating", workspaces: "shown", wifi: "shown"
        } }).capsulePlaces;

        compare(places.battery, "shown");
        compare(places.media, "liveRight");
        compare(places.recording, "hidden");
        compare(places.clock, "shown");
        compare(places.arch, "shown");
        compare(places.notifications, "shown");
        compare(places.workspaces, undefined);
        compare(places.wifi, undefined);
    }

    // Choosing a place sets it, without changing the places it was given; a
    // place the element can't take changes nothing.
    function test_choosingACollapsedPlace() {
        const places = BarProfileModel.completeCapsulePlaces(undefined);

        compare(BarProfileModel.setCapsulePlace(places, "keepAwake", "liveLeft").keepAwake, "liveLeft");
        compare(BarProfileModel.setCapsulePlace(places, "media", "liveRight").media, "liveRight");
        compare(BarProfileModel.setCapsulePlace(places, "battery", "shown").battery, "shown");
        compare(BarProfileModel.setCapsulePlace(places, "battery", "liveLeft").battery, "hidden");
        compare(BarProfileModel.setCapsulePlace(places, "workspaces", "shown").workspaces, undefined);
        compare(places.media, "liveLeft");
    }

    // The elements in each collapsed place follow the profile's order, the
    // live ones by side, disabled ones too; the workspaces are in none.
    function test_theElementsInEachCollapsedPlaceFollowTheProfilesOrder() {
        const barElements = {
            left: [{ id: "clock", enabled: true }, { id: "recording", enabled: false }],
            center: [{ id: "workspaces", enabled: true }],
            right: [{ id: "keepAwake", enabled: true }, { id: "arch", enabled: true },
                { id: "media", enabled: true }]
        };
        const places = Object.assign(BarProfileModel.completeCapsulePlaces(undefined),
            { clock: "shown", arch: "shown", keepAwake: "liveRight", media: "liveRight" });

        compare(BarProfileModel.capsulePlaceIds(barElements, places),
            { hidden: [], shown: ["clock", "arch"], live: { left: [], right: ["recording", "keepAwake", "media"] } });
    }

    // Every bar element but the workspaces offers Hidden and Shown; only the
    // ones that can be live, the recording indicator, media and keep-awake,
    // also offer Live left and Live right.
    function test_onlyElementsThatCanBeLiveOfferTheLivePlaces_data() {
        const all = ["Hidden", "Shown", "Live left", "Live right"];
        return [
            { tag: "recording", id: "recording", labels: all },
            { tag: "media", id: "media", labels: all },
            { tag: "clock", id: "clock", labels: ["Hidden", "Shown"] },
            { tag: "keepAwake", id: "keepAwake", labels: all },
            { tag: "workspaces", id: "workspaces", labels: [] }
        ];
    }

    function test_onlyElementsThatCanBeLiveOfferTheLivePlaces(data) {
        compare(BarProfileModel.capsulePlaceChoices(data.id).map(choice => choice.label), data.labels);
    }

    function test_choosingTheCapsuleOnASideBarMovesItToTheTop() {
        const side = fixtures.edited(fixtures.startedBarState(), { barPosition: "left" });
        const capsule = fixtures.edited(side, { barStyle: "capsule" });

        compare(BarProfileModel.editedProfile(capsule).barStyle, "capsule");
        compare(BarProfileModel.editedProfile(capsule).barPosition, "top");
    }

    function test_theBarPositionsABarStyleCanTake() {
        compare(BarProfileModel.barPositionsFor("capsule"), ["top", "bottom"]);
        compare(BarProfileModel.barPositionsFor("docked"), ["top", "bottom", "left", "right"]);
    }

    function test_choosingABarPositionIsAPendingChangeUntilSaved() {
        const state = fixtures.edited(fixtures.startedBarState(), { barPosition: "bottom" });

        verify(BarProfileModel.isModified(state));
        compare(BarProfileModel.editedProfile(state).barPosition, "bottom");
        compare(BarProfileModel.savedProfile(state, "minimal").barPosition, "top");

        const discarded = fixtures.withChanges(state, BarProfileModel.discardChanges(state));
        compare(BarProfileModel.editedProfile(discarded).barPosition, "top");

        const saved = fixtures.withChanges(state, BarProfileModel.saveProfile(state));
        compare(BarProfileModel.savedProfile(saved, "minimal").barPosition, "bottom");
    }

    // Each monitor's bar window reads its own profile, so two monitors can differ.
    function test_twoProfilesCanHaveDifferentBarPositions() {
        const state = fixtures.edited(fixtures.startedBarState(), { barPosition: "bottom" });

        compare(BarProfileModel.profileValue(state, "minimal", "barPosition"), "bottom");
        compare(BarProfileModel.profileValue(state, "presentation", "barPosition"), "top");
    }

    function test_theDefaultProfilesAreInTheCurrentSchema() {
        const profiles = BarProfileModel.defaultBarProfiles();

        compare(Object.keys(profiles).sort(), ["media", "minimal", "presentation", "work"]);
        for (const name in profiles)
            compare(profiles[name], BarProfileModel.completeProfile(profiles[name]), name);
    }

    function test_densityPresetsFillInTheBarSizes() {
        compare(BarProfileModel.densityPresetChanges("compact"), {
            barHeight: 30, horizontalPadding: 8, spacing: 4,
            pillVerticalPadding: 2, textSize: 13, iconSize: 13
        });
        compare(BarProfileModel.densityPresetChanges("spacious"), {
            barHeight: 38, horizontalPadding: 16, spacing: 12,
            pillVerticalPadding: 5, textSize: 15, iconSize: 15
        });
        compare(BarProfileModel.densityPresetChanges("balanced"), {
            barHeight: 34, horizontalPadding: 12, spacing: 8,
            pillVerticalPadding: 3, textSize: 14, iconSize: 14
        });
    }

    function test_aMonitorUsesItsAssignedProfile() {
        const displaySettings = {
            "DP-1": { barProfile: "presentation", barVisible: false },
            "DP-2": { barProfile: "work" }
        };

        compare(BarProfileModel.profileForMonitor(displaySettings, "DP-1"), "presentation");
        compare(BarProfileModel.monitorDisplaySettings(displaySettings, "DP-1"),
            { barVisible: false, barProfile: "presentation" });
        compare(BarProfileModel.monitorDisplaySettings(displaySettings, "DP-2"),
            { barVisible: true, barProfile: "work" });
    }

    function test_noOtherEntryStandsInForAMonitor() {
        const displaySettings = { "default": { barProfile: "work", barVisible: false } };

        compare(BarProfileModel.monitorDisplaySettings(displaySettings, "HDMI-9"),
            { barVisible: true, barProfile: "" });
    }

    function test_aNeverSeenMonitorIsAssignedTheDefaultProfile() {
        const barProfiles = fixtures.startedBarState().barProfiles;

        const updated = BarProfileModel.assignNewMonitor({ "DP-1": { barProfile: "work" } },
            "HDMI-9", barProfiles);

        compare(updated["HDMI-9"], { barVisible: true, barProfile: "minimal" });
        compare(updated["DP-1"], { barProfile: "work" });
    }

    function test_withoutMinimalANewMonitorGetsTheFirstProfile() {
        const updated = BarProfileModel.assignNewMonitor({}, "HDMI-9", { work: {}, media: {} });

        compare(updated["HDMI-9"].barProfile, "media");
    }

    function test_aMonitorWithAProfileIsNotReassigned() {
        const displaySettings = { "DP-1": { barProfile: "work" } };

        compare(BarProfileModel.assignNewMonitor(displaySettings, "DP-1",
            fixtures.startedBarState().barProfiles), null);
    }

    function test_aMonitorWithOtherSettingsButNoProfileGetsOne() {
        const updated = BarProfileModel.assignNewMonitor(
            { "DP-1": { barVisible: false, desktopWidgets: {} } }, "DP-1", { work: {} });

        compare(updated["DP-1"], { barVisible: false, desktopWidgets: {}, barProfile: "work" });
    }
}
