import QtQuick
import QtTest
import "../config/BarProfileModel.js" as BarProfileModel

TestCase {
    name: "BarProfileModel"

    function readFixture(fileName) {
        const request = new XMLHttpRequest();
        request.open("GET", Qt.resolvedUrl("fixtures/" + fileName), false);
        request.send(null);
        return JSON.parse(request.responseText);
    }

    function test_applyingAProfileCopiesItsSavedValuesAndMakesItActive() {
        const state = readFixture("appearance.json");

        const changes = BarProfileModel.applyProfile(state, "presentation");

        compare(changes.activeBarProfile, "presentation");
        compare(changes.barHeight, 30);
        compare(changes.horizontalPadding, 12);
        compare(changes.statusModuleOrder, ["media", "audio", "network", "battery", "clock",
            "notifications", "recording", "bluetooth", "tray"]);
        compare(changes.barElementEnabled.arch, false);
    }

    function test_applyingAProfileLeavesSettingsItDoesNotSaveUntouched() {
        const state = readFixture("appearance.json");

        const changes = BarProfileModel.applyProfile(state, "work");

        compare(changes.barHeight, 30);
        verify(!("barOpacity" in changes));
        verify(!("doNotDisturb" in changes));
    }

    function test_applyingAnUnknownProfileChangesNothing() {
        const state = readFixture("appearance.json");

        compare(BarProfileModel.applyProfile(state, "missing"), null);
    }

    function test_applyingAProfileDoesNotShareObjectsWithTheSavedProfile() {
        const state = readFixture("appearance.json");

        const changes = BarProfileModel.applyProfile(state, "presentation");
        changes.barElementEnabled.arch = true;

        compare(state.barProfiles.presentation.barElementEnabled.arch, false);
    }

    function test_savingStoresTheLiveBarIntoTheProfileAndMakesItActive() {
        const state = readFixture("appearance.json");
        state.barHeight = 41;

        const changes = BarProfileModel.saveProfile(state, "work");

        compare(changes.activeBarProfile, "work");
        compare(changes.barProfiles.work.barHeight, 41);
        compare(changes.barProfiles.work.barOpacity, 90);
        verify(!("doNotDisturb" in changes.barProfiles.work));
        compare(changes.barProfiles.media.barHeight, 34);
        compare(state.barProfiles.work.barHeight, 30);
    }

    function test_savingUnderANewNameAddsAProfile() {
        const state = readFixture("appearance.json");

        const changes = BarProfileModel.saveProfile(state, "laptop");

        compare(Object.keys(changes.barProfiles).sort(),
            ["laptop", "media", "minimal", "presentation", "work"]);
        compare(changes.barProfiles.laptop.horizontalPadding, 16);
    }

    function test_readingTheActiveProfileReturnsTheLiveValue() {
        const state = readFixture("appearance.json");
        state.barHeight = 41;

        compare(BarProfileModel.profileValue(state, "minimal", "barHeight"), 41);
    }

    function test_readingAnInactiveProfileReturnsItsSavedValue() {
        const state = readFixture("appearance.json");
        state.barHeight = 41;

        compare(BarProfileModel.profileValue(state, "presentation", "barHeight"), 30);
    }

    function test_readingAKeyAnInactiveProfileDoesNotSaveFallsBackToTheLiveValue() {
        const state = readFixture("appearance.json");
        state.barOpacity = 75;

        compare(BarProfileModel.profileValue(state, "work", "barOpacity"), 75);
        compare(BarProfileModel.profileValue(state, "missing", "barHeight"), 34);
    }

    function test_densityPresetsFillInTheBarSizes() {
        compare(BarProfileModel.densityPresetChanges("compact"), {
            densityPreset: "compact", barHeight: 30, horizontalPadding: 8, spacing: 4,
            pillVerticalPadding: 2, workspacePadding: 3, textSize: 13
        });
        compare(BarProfileModel.densityPresetChanges("spacious"), {
            densityPreset: "spacious", barHeight: 38, horizontalPadding: 16, spacing: 12,
            pillVerticalPadding: 5, workspacePadding: 5, textSize: 15
        });
        compare(BarProfileModel.densityPresetChanges("balanced"), {
            densityPreset: "balanced", barHeight: 34, horizontalPadding: 12, spacing: 8,
            pillVerticalPadding: 3, workspacePadding: 4, textSize: 14
        });
    }

    function test_aMonitorUsesItsAssignedProfileOrTheFallback() {
        const displaySettings = readFixture("monitors.json").displaySettings;
        displaySettings["DP-1"] = { barProfile: "presentation" };

        compare(BarProfileModel.profileForMonitor(displaySettings, "DP-1", "minimal"), "presentation");
        compare(BarProfileModel.profileForMonitor(displaySettings,
            "Philips Consumer Electronics Company PHL 243V7 0x00009A4C", "minimal"), "minimal");
        compare(BarProfileModel.profileForMonitor(displaySettings, "HDMI-9", "work"), "work");
    }

    function test_monitorDisplaySettingsFallBackToTheDefaultEntry() {
        const displaySettings = {
            "default": { barVisible: false, backgroundClockVisible: true, barProfile: "media" },
            "DP-1": { barVisible: true }
        };

        compare(BarProfileModel.monitorDisplaySettings(displaySettings, "DP-1"),
            { barVisible: true, backgroundClockVisible: true, barProfile: "media" });
        compare(BarProfileModel.monitorDisplaySettings({}, "DP-2"),
            { barVisible: true, backgroundClockVisible: true, barProfile: "" });
    }
}
