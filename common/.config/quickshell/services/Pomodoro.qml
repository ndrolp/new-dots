import Quickshell.Io
import QtQuick
import "PomodoroPhases.js" as PomodoroPhases

// The pomodoro: a focus phase of the chosen duration, then a short break
// (PomodoroPhases.js), counted down a second at a time.
QtObject {
    id: root

    property int durationSeconds: 25 * 60
    property int breakSeconds: 5 * 60
    // "work" (focus) or "break".
    property string phase: "work"
    // How long the current phase is: what its ring is measured against.
    readonly property int phaseSeconds: PomodoroPhases.length(phase, {
        durationSeconds: durationSeconds,
        breakSeconds: breakSeconds
    })
    property int remainingSeconds: durationSeconds
    property bool running: false
    property bool started: false

    readonly property string remainingLabel: {
        const minutes = Math.floor(remainingSeconds / 60);
        const seconds = remainingSeconds % 60;
        return minutes + ":" + (seconds < 10 ? "0" : "") + seconds;
    }

    function selectMinutes(minutes) {
        durationSeconds = minutes * 60;
        phase = "work";
        remainingSeconds = durationSeconds;
        running = false;
        started = false;
    }

    function adjustMinutes(minutes) {
        durationSeconds = Math.max(10 * 60, durationSeconds + (minutes * 60));
        remainingSeconds = Math.max(0, remainingSeconds + (minutes * 60));
    }

    function start() {
        if (remainingSeconds <= 0)
            remainingSeconds = phaseSeconds;

        started = true;
        running = true;
    }

    function stop() {
        running = false;
    }

    function cancel() {
        running = false;
        started = false;
        phase = "work";
        remainingSeconds = durationSeconds;
    }

    // Moves on to the next phase: from focus to a running break, from a
    // break back to an unstarted focus.
    function skip() {
        const next = PomodoroPhases.next(phase, {
            durationSeconds: durationSeconds,
            breakSeconds: breakSeconds
        });
        phase = next.phase;
        remainingSeconds = next.remainingSeconds;
        started = next.started;
        running = next.running;
    }

    function complete() {
        const wasBreak = phase === "break";
        skip();
        completionSound.exec(["pw-play", "/usr/share/sounds/freedesktop/stereo/complete.oga"]);
        completionNotification.exec(wasBreak
            ? ["notify-send", "-a", "Pomodoro", "-u", "normal", "Break over", "Time to focus again."]
            : ["notify-send", "-a", "Pomodoro", "-u", "normal",
                "Pomodoro complete", "Your focus timer has finished. Take a break."]);
    }

    property var tickTimer: Timer {
        interval: 1000
        running: root.running
        repeat: true
        onTriggered: {
            if (root.remainingSeconds <= 1)
                root.complete();
            else
                root.remainingSeconds--;
        }
    }

    property var completionSound: Process {
        id: completionSound
    }

    property var completionNotification: Process {
        id: completionNotification
    }
}
