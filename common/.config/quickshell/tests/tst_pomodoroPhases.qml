import QtQuick
import QtTest
import "../services/PomodoroPhases.js" as PomodoroPhases

// The pomodoro's phases (services/Pomodoro.qml): a focus phase, then a
// break. Skipping, or a phase running out, moves on to the next phase:
// focus to a running break, a break back to an unstarted focus. Each phase's
// length is what its ring is measured against.
TestCase {
    name: "PomodoroPhases"

    readonly property var lengths: ({ durationSeconds: 25 * 60, breakSeconds: 5 * 60 })

    function test_afterFocusABreakRuns() {
        compare(PomodoroPhases.next("work", lengths),
            { phase: "break", remainingSeconds: 300, running: true, started: true });
    }

    function test_afterABreakFocusWaitsToBeStarted() {
        compare(PomodoroPhases.next("break", lengths),
            { phase: "work", remainingSeconds: 1500, running: false, started: false });
    }

    function test_eachPhaseHasItsLength_data() {
        return [
            { tag: "focus", phase: "work", seconds: 1500 },
            { tag: "break", phase: "break", seconds: 300 }
        ];
    }

    function test_eachPhaseHasItsLength(data) {
        compare(PomodoroPhases.length(data.phase, lengths), data.seconds);
    }
}
