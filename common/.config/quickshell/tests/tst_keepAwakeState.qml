import QtQuick
import QtTest
import "../services/KeepAwakeState.js" as KeepAwakeState

// Keep-awake's duration and countdown: turning it on with the selected
// duration, restarting the countdown on a new duration, running out with a
// notification and turning it off by hand without one. KeepAwake.qml carries
// the decisions out.
TestCase {
    name: "KeepAwakeState"

    readonly property int minute: 60 * 1000

    function test_turningOnWithATimedDurationStartsItsCountdown() {
        const chosen = KeepAwakeState.durationChosen(KeepAwakeState.off, 30, 0);

        const on = KeepAwakeState.toggled(chosen, 1000);

        compare(on.on, true);
        compare(KeepAwakeState.secondsLeft(on, 1000), 30 * 60);
        compare(KeepAwakeState.secondsLeft(on, 1000 + 10 * minute), 20 * 60);
    }

    function test_choosingADurationWhileOnRestartsTheCountdownFromIt() {
        const on = KeepAwakeState.toggled(KeepAwakeState.durationChosen(KeepAwakeState.off, 30, 0), 0);

        const restarted = KeepAwakeState.durationChosen(on, 120, 20 * minute);

        compare(restarted.on, true);
        compare(KeepAwakeState.secondsLeft(restarted, 20 * minute), 120 * 60);
    }

    function test_choosingUntilTurnedOffWhileOnKeepsItOnWithNoCountdown() {
        const on = KeepAwakeState.toggled(KeepAwakeState.durationChosen(KeepAwakeState.off, 60, 0), 0);

        const untimed = KeepAwakeState.durationChosen(on, KeepAwakeState.untilTurnedOff, 5 * minute);

        compare(untimed.on, true);
        compare(KeepAwakeState.timed(untimed), false);
        compare(KeepAwakeState.ticked(untimed, 600 * minute).state.on, true);
    }

    function test_choosingADurationWhileOffOnlySelectsIt() {
        const chosen = KeepAwakeState.durationChosen(KeepAwakeState.off, 60, 0);

        compare(chosen.on, false);
        compare(chosen.duration, 60);
        compare(KeepAwakeState.timed(chosen), false);
    }

    function test_theShellStartsOffWithUntilTurnedOffSelected() {
        compare(KeepAwakeState.off.on, false);
        compare(KeepAwakeState.off.duration, KeepAwakeState.untilTurnedOff);
    }

    function test_thePopupOffersUntilTurnedOffAndThreeDurations() {
        compare(KeepAwakeState.durations.map(d => d.minutes), [KeepAwakeState.untilTurnedOff, 30, 60, 120]);
        compare(KeepAwakeState.durations.map(d => d.label), ["Until turned off", "30 min", "1 h", "2 h"]);
    }

    function timedOn(duration, now) {
        return KeepAwakeState.toggled(KeepAwakeState.durationChosen(KeepAwakeState.off, duration, 0), now);
    }

    function test_beforeTheCountdownRunsOutKeepAwakeStaysOn() {
        const tick = KeepAwakeState.ticked(timedOn(30, 0), 30 * minute - 1);

        compare(tick.state.on, true);
        compare(tick.ended, false);
        compare(KeepAwakeState.secondsLeft(tick.state, 30 * minute - 1), 1);
    }

    function test_whenTheCountdownRunsOutKeepAwakeTurnsOffAndSaysItEnded() {
        const tick = KeepAwakeState.ticked(timedOn(30, 0), 30 * minute);

        compare(tick.state.on, false);
        compare(tick.ended, true);
        compare(KeepAwakeState.timed(tick.state), false);
        compare(KeepAwakeState.secondsLeft(tick.state, 30 * minute), 0);
    }

    function test_theSelectedDurationOutlivesTheCountdownRunningOut() {
        const ended = KeepAwakeState.ticked(timedOn(60, 0), 61 * minute).state;

        compare(ended.duration, 60);
        compare(KeepAwakeState.secondsLeft(KeepAwakeState.toggled(ended, 61 * minute), 61 * minute), 60 * 60);
    }

    function test_turningATimedKeepAwakeOffByHandClearsTheCountdownWithoutEnding() {
        const offByHand = KeepAwakeState.toggled(timedOn(30, 0), 10 * minute);

        compare(offByHand.on, false);
        compare(KeepAwakeState.timed(offByHand), false);
        compare(KeepAwakeState.ticked(offByHand, 30 * minute).ended, false);
    }

    function test_turningAnUntimedKeepAwakeOffByHandDoesNotEnd() {
        const offByHand = KeepAwakeState.toggled(KeepAwakeState.toggled(KeepAwakeState.off, 0), 10 * minute);

        compare(offByHand.on, false);
        compare(KeepAwakeState.ticked(offByHand, 600 * minute).ended, false);
    }

    function test_anEndedKeepAwakeEndsOnlyOnce() {
        const ended = KeepAwakeState.ticked(timedOn(30, 0), 30 * minute).state;

        compare(KeepAwakeState.ticked(ended, 31 * minute).ended, false);
        compare(KeepAwakeState.ticked(KeepAwakeState.durationChosen(ended, 60, 31 * minute), 31 * minute).ended, false);
    }

    function test_theEndNotificationIsANormalOneFromKeepAwake() {
        compare(KeepAwakeState.endedNotificationCommand, [
            "notify-send", "-a", "Keep-awake", "-u", "normal",
            "Keep-awake ended", "The PC can go idle and sleep again."
        ]);
    }

    function test_keepAwakeShowsAFilledCupWhileOnAndAnOutlineOneWhileOff() {
        compare(KeepAwakeState.cup(true), "󰅶");
        compare(KeepAwakeState.cup(false), "󰛊");
    }

    function test_theTimeLeftReadsAsMinutesAndSecondsOrHours() {
        compare(KeepAwakeState.timeLeftLabel(30 * 60), "30:00");
        compare(KeepAwakeState.timeLeftLabel(9 * 60 + 5), "9:05");
        compare(KeepAwakeState.timeLeftLabel(2 * 3600), "2:00:00");
        compare(KeepAwakeState.timeLeftLabel(3600 + 61), "1:01:01");
    }

    function test_theKeybindOsdSaysKeepAwakeIsOffWhenTurnedOff() {
        compare(KeepAwakeState.osdLabel(false, 60), "Keep-awake off");
    }

    function test_theKeybindOsdSaysOnWithoutADurationUntilTurnedOff() {
        compare(KeepAwakeState.osdLabel(true, KeepAwakeState.untilTurnedOff), "Keep-awake on");
    }

    function test_theKeybindOsdSaysOnWithTheSelectedDuration() {
        compare(KeepAwakeState.osdLabel(true, 30), "Keep-awake on · 30 min");
        compare(KeepAwakeState.osdLabel(true, 60), "Keep-awake on · 1 h");
        compare(KeepAwakeState.osdLabel(true, 120), "Keep-awake on · 2 h");
    }
}
