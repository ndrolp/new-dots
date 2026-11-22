import QtQuick
import QtTest
import "../components/bar/PomodoroRing.js" as PomodoroRing

// The pomodoro's ring inside a capsule and at rest: how much of it is drawn
// (the time left in the phase) and in which colour (the phase's, from the
// colorscheme), and the phase's name.
TestCase {
    name: "PomodoroRing"

    readonly property var colours: ({ red: "#ff0000", green: "#00ff00", accent: "#0000ff" })

    function test_theRingIsTheTimeLeftInThePhase_data() {
        return [
            { tag: "just started", remaining: 1500, total: 1500, fraction: 1 },
            { tag: "halfway", remaining: 150, total: 300, fraction: 0.5 },
            { tag: "a quarter left", remaining: 375, total: 1500, fraction: 0.25 },
            { tag: "done", remaining: 0, total: 1500, fraction: 0 },
            { tag: "more left than the phase (shortened)", remaining: 2000, total: 600, fraction: 1 },
            { tag: "no phase length", remaining: 10, total: 0, fraction: 0 }
        ];
    }

    function test_theRingIsTheTimeLeftInThePhase(data) {
        compare(PomodoroRing.fraction(data.remaining, data.total), data.fraction);
    }

    function test_workAndBreakTakeDifferentColoursFromTheColorscheme_data() {
        return [
            { tag: "work", phase: "work", colour: "#ff0000" },
            { tag: "break", phase: "break", colour: "#00ff00" }
        ];
    }

    function test_workAndBreakTakeDifferentColoursFromTheColorscheme(data) {
        compare(PomodoroRing.phaseColor(data.phase, colours), data.colour);
    }

    function test_thePhaseIsNamed_data() {
        return [
            { tag: "work", phase: "work", name: "Focus" },
            { tag: "break", phase: "break", name: "Break" }
        ];
    }

    function test_thePhaseIsNamed(data) {
        compare(PomodoroRing.phaseName(data.phase), data.name);
    }
}
