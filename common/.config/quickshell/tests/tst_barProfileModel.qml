import QtQuick
import QtTest
import "../config/BarProfileModel.js" as BarProfileModel

TestCase {
    name: "BarProfileModel"

    Fixtures {
        id: fixtures
    }

    function test_editingAProfileShowsItsSavedValues() {
        const state = fixtures.startedBarState();

        const after = fixtures.withChanges(state, BarProfileModel.editProfile(state, "presentation"));

        const edited = BarProfileModel.editedProfile(after);
        compare(edited.barHeight, 30);
        compare(edited.horizontalPadding, 12);
        compare(edited.transparentBarSlanted, true);
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

    function test_theDefaultProfilesAreInTheCurrentSchema() {
        const profiles = BarProfileModel.defaultBarProfiles();

        compare(Object.keys(profiles).sort(), ["media", "minimal", "presentation", "work"]);
        for (const name in profiles)
            compare(profiles[name], BarProfileModel.completeProfile(profiles[name]), name);
    }

    function test_densityPresetsFillInTheBarSizes() {
        compare(BarProfileModel.densityPresetChanges("compact"), {
            barHeight: 30, horizontalPadding: 8, spacing: 4,
            pillVerticalPadding: 2, workspacePadding: 3, textSize: 13
        });
        compare(BarProfileModel.densityPresetChanges("spacious"), {
            barHeight: 38, horizontalPadding: 16, spacing: 12,
            pillVerticalPadding: 5, workspacePadding: 5, textSize: 15
        });
        compare(BarProfileModel.densityPresetChanges("balanced"), {
            barHeight: 34, horizontalPadding: 12, spacing: 8,
            pillVerticalPadding: 3, workspacePadding: 4, textSize: 14
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
