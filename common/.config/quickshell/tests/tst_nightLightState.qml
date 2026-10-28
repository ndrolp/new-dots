import QtQuick
import QtTest
import "../services/NightLightState.js" as NightLightState

// Night light: the temperature it warms the screen to and how the saved one
// reads back, how hyprsunset is run, and turning it on and off, including
// when hyprsunset can't run. NightLight.qml carries the decisions out.
TestCase {
    name: "NightLightState"

    function test_theTemperatureStaysBetweenWarmAndNeutral() {
        compare(NightLightState.temperature(1000), 2500);
        compare(NightLightState.temperature(9000), 6000);
        compare(NightLightState.temperature(2500), 2500);
        compare(NightLightState.temperature(6000), 6000);
    }

    function test_theTemperatureMovesInStepsOfAHundredKelvin() {
        compare(NightLightState.temperature(4049), 4000);
        compare(NightLightState.temperature(4050), 4100);
    }

    function test_aSavedTemperatureReadsBackAsSaved() {
        compare(NightLightState.temperature(3300), 3300);
    }

    function test_aMissingOrUnreadableSavedTemperatureIsTheDefault() {
        compare(NightLightState.temperature(undefined), 4000);
        compare(NightLightState.temperature(null), 4000);
        compare(NightLightState.temperature("warm"), 4000);
        compare(NightLightState.temperature(NaN), 4000);
    }

    function test_hyprsunsetRunsAtTheTemperatureAsItsOwnArgument() {
        compare(NightLightState.startCommand(3300),
            ["sh", "-c", "exec hyprsunset -t \"$1\"", "sh", "3300"]);
    }

    function test_aNewTemperatureReachesTheRunningHyprsunset() {
        compare(NightLightState.temperatureCommand(4500),
            ["hyprctl", "hyprsunset", "temperature", "4500"]);
    }

    function test_nightLightStartsOff() {
        verify(!NightLightState.off.on);
        compare(NightLightState.off.failureHint, "");
    }

    function test_toggleTurnsItOnAndOff() {
        const on = NightLightState.toggled(NightLightState.off);
        verify(on.on);
        verify(!NightLightState.toggled(on).on);
    }

    function test_stoppingHyprsunsetOnPurposeIsNoFailure() {
        const off = NightLightState.toggled(NightLightState.toggled(NightLightState.off));
        compare(NightLightState.exited(off, 0), NightLightState.off);
    }

    function test_aMissingHyprsunsetTurnsItOffAndSaysWhy() {
        const state = NightLightState.exited(NightLightState.toggled(NightLightState.off), 127);
        verify(!state.on);
        compare(state.failureHint, "hyprsunset isn't installed, so night light can't turn on.");
    }

    function test_hyprsunsetStoppingOnItsOwnTurnsItOffAndSaysSo() {
        const state = NightLightState.exited(NightLightState.toggled(NightLightState.off), 1);
        verify(!state.on);
        compare(state.failureHint, "hyprsunset stopped, so night light turned off.");
    }

    function test_turningItOnAgainClearsTheHint() {
        const failed = NightLightState.exited(NightLightState.toggled(NightLightState.off), 127);
        compare(NightLightState.toggled(failed).failureHint, "");
    }
}
