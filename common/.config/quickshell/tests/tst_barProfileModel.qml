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

        BarProfileModel.editedProfile(state).workspaceGlyphs[0] = "x";

        compare(state.barProfiles.minimal.workspaceGlyphs[0], "");
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

    function test_aMonitorUsesItsAssignedProfileOrTheDefaultEntry() {
        const displaySettings = {
            "default": { barProfile: "work" },
            "DP-1": { barProfile: "presentation" },
            "DP-2": { barVisible: true }
        };

        compare(BarProfileModel.profileForMonitor(displaySettings, "DP-1"), "presentation");
        compare(BarProfileModel.profileForMonitor(displaySettings, "DP-2"), "work");
        compare(BarProfileModel.profileForMonitor(displaySettings, "HDMI-9"), "work");
    }

    function test_aNewMonitorGetsTheDefaultProfile() {
        compare(BarProfileModel.profileForMonitor({}, "HDMI-9"), "minimal");
        compare(BarProfileModel.monitorDisplaySettings({ "default": { barProfile: "" } }, "HDMI-9"),
            { barVisible: true, barProfile: "minimal" });
    }

    function test_monitorDisplaySettingsFallBackToTheDefaultEntry() {
        const displaySettings = {
            "default": { barVisible: false, barProfile: "media" },
            "DP-1": { barVisible: true }
        };

        compare(BarProfileModel.monitorDisplaySettings(displaySettings, "DP-1"),
            { barVisible: true, barProfile: "media" });
        compare(BarProfileModel.monitorDisplaySettings({}, "DP-2"),
            { barVisible: true, barProfile: "minimal" });
    }
}
