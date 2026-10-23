import QtQuick
import QtTest
import "../config/BarProfileModel.js" as BarProfileModel

TestCase {
    name: "BarProfileModel"

    Fixtures {
        id: fixtures
    }

    // The appearance fixture after "activeBarProfile" became the edited profile.
    function editingState() {
        const state = fixtures.read("appearance.json");
        state.editingBarProfile = state.activeBarProfile;
        delete state.activeBarProfile;
        return state;
    }

    function withChanges(state, changes) {
        const updated = Object.assign({}, state);
        for (const key in changes)
            updated[key] = changes[key];
        return updated;
    }

    function test_editingAProfileLoadsItsSavedValues() {
        const state = editingState();

        const changes = BarProfileModel.editProfile(state, "presentation");

        compare(changes.editingBarProfile, "presentation");
        compare(changes.barHeight, 30);
        compare(changes.horizontalPadding, 12);
        compare(changes.transparentBarSlanted, true);
        compare(changes.transparentBarTopMargin, 8);
    }

    function test_editingAProfileLeavesSettingsItDoesNotSaveUntouched() {
        const state = editingState();

        const changes = BarProfileModel.editProfile(state, "work");

        compare(changes.barHeight, 30);
        // "work" saves no opacity: it keeps the one its monitors drew.
        compare(withChanges(state, changes).barOpacity, state.barOpacity);
        verify(!("doNotDisturb" in changes));
    }

    function test_editingAnUnknownProfileChangesNothing() {
        const state = editingState();

        compare(BarProfileModel.editProfile(state, "missing"), null);
    }

    function test_editingAProfileDoesNotShareObjectsWithTheSavedProfile() {
        const state = editingState();

        const changes = BarProfileModel.editProfile(state, "presentation");
        changes.workspaceGlyphs[0] = "x";

        compare(state.barProfiles.presentation.workspaceGlyphs[0], "");
    }

    function test_savingStoresTheLiveBarIntoTheProfileAndEditsIt() {
        const state = editingState();
        state.barHeight = 41;

        const changes = BarProfileModel.saveProfile(state, "work");

        compare(changes.editingBarProfile, "work");
        compare(changes.barProfiles.work.barHeight, 41);
        compare(changes.barProfiles.work.barOpacity, 90);
        verify(!("doNotDisturb" in changes.barProfiles.work));
        compare(changes.barProfiles.media.barHeight, 34);
        compare(state.barProfiles.work.barHeight, 30);
    }

    function test_savingUnderANewNameAddsAProfile() {
        const state = editingState();

        const changes = BarProfileModel.saveProfile(state, "laptop");

        compare(Object.keys(changes.barProfiles).sort(),
            ["laptop", "media", "minimal", "presentation", "work"]);
        compare(changes.barProfiles.laptop.horizontalPadding, 16);
    }

    function test_readingTheEditedProfileReturnsTheLiveValue() {
        const state = editingState();
        state.barHeight = 41;

        compare(BarProfileModel.profileValue(state, "minimal", "barHeight"), 41);
    }

    function test_readingAProfileNotBeingEditedReturnsItsSavedValue() {
        const state = editingState();
        state.barHeight = 41;

        compare(BarProfileModel.profileValue(state, "presentation", "barHeight"), 30);
    }

    function test_readingAKeyAProfileNotBeingEditedDoesNotSaveFallsBackToTheLiveValue() {
        const state = editingState();
        state.barOpacity = 75;

        compare(BarProfileModel.profileValue(state, "work", "barOpacity"), 75);
        compare(BarProfileModel.profileValue(state, "missing", "barHeight"), 34);
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
