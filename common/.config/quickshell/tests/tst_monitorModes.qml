import QtQuick
import QtTest
import "../services/MonitorModes.js" as MonitorModes

// The monitor's resolution, refresh rate and scale choices.
TestCase {
    name: "MonitorModes"

    readonly property var aoc: MonitorModes.parsedModes([
        "1920x1080@60.00Hz", "2560x1440@59.95Hz", "2560x1440@143.91Hz", "1920x1080@100.00Hz",
        "1920x1080@143.91Hz", "1280x720@50.00Hz", "1280x720@60.00Hz"
    ])

    function test_modesReadFromHyprctlStayNumbers() {
        const modes = MonitorModes.parsedModes(["2880x1800@120.00Hz"]);
        compare(modes.length, 1);
        compare(modes[0].width, 2880);
        compare(modes[0].height, 1800);
        compare(modes[0].refresh, 120);
    }

    function test_aModeInASavedSetupCanLeaveOutTheRate() {
        compare(MonitorModes.parsedMode("2560x1440").refresh, 0);
        compare(MonitorModes.parsedMode("2560x1440@143.91").refresh, 143.91);
    }

    function test_aModeThatIsNoSizeIsNotAMode() {
        compare(MonitorModes.parsedMode("preferred"), null);
    }

    function test_aModeIsWrittenTheWaySetupsSaveIt() {
        compare(MonitorModes.modeText(2560, 1440, 143.912), "2560x1440@143.91");
    }

    function test_resolutionsAreListedOnceLargestFirst() {
        compare(MonitorModes.resolutions(aoc).map(r => r.label),
            ["2560x1440", "1920x1080", "1280x720"]);
    }

    function test_theRefreshListHasOnlyTheChosenResolutionsRatesHighestFirst() {
        compare(MonitorModes.refreshRates(aoc, 2560, 1440), [143.91, 59.95]);
        compare(MonitorModes.refreshRates(aoc, 1280, 720), [60, 50]);
    }

    function test_changingResolutionKeepsTheRateIfItIsAvailable() {
        const mode = MonitorModes.afterResolution(aoc, 1920, 1080, 100);
        compare(mode.refresh, 100);
    }

    function test_changingResolutionKeepsARateThatOnlyRoundsDifferently() {
        const mode = MonitorModes.afterResolution(aoc, 2560, 1440, 60);
        compare(mode.refresh, 59.95);
    }

    function test_changingResolutionTakesTheHighestRateOtherwise() {
        const mode = MonitorModes.afterResolution(aoc, 1280, 720, 143.91);
        compare(mode.refresh, 60);
    }

    function test_theHighestModeIsTheLargestAtItsTopRate() {
        const mode = MonitorModes.highest(aoc);
        compare([mode.width, mode.height, mode.refresh], [2560, 1440, 143.91]);
    }

    function test_scalePresetsAreTheSpecsOnes() {
        compare(MonitorModes.scaleChoices(1), [1, 1.25, 1.5, 1.6, 1.75, 2]);
    }

    function test_aScaleFromAnImportedSetupJoinsThePresetsInOrder() {
        compare(MonitorModes.scaleChoices(1.33), [1, 1.25, 1.33, 1.5, 1.6, 1.75, 2]);
    }

    // The expected values below come from a separate exact-fraction run of the search in
    // src/output/Monitor.cpp (Hyprland v0.57.0), not from this code.
    function test_aScaleWithWholeLogicalSidesIsAccepted() {
        compare(MonitorModes.nearestScale(2880, 1800, 1.6), 1.6);
        compare(MonitorModes.nearestScale(2560, 1440, 1.25), 1.25);
    }

    function test_aScaleHyprlandWontAcceptSnapsToTheNearestItWill() {
        compare(MonitorModes.nearestScale(1920, 1080, 1.75), 200 / 120);
        compare(MonitorModes.nearestScale(2880, 1800, 1.75), 216 / 120);
        compare(MonitorModes.nearestScale(1366, 768, 1.25), 1);
    }

    // No clean value lies within Hyprland's search of 3, so there is nothing to snap to.
    function test_aScaleWithNoCleanValueNearbyHasNoNearest() {
        compare(MonitorModes.nearestScale(1921, 1081, 3), null);
    }
}
