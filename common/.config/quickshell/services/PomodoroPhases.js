.pragma library

// The pomodoro's phases (Pomodoro.qml): "work", a focus phase as long as the
// chosen duration, then "break". `lengths` is { durationSeconds,
// breakSeconds }.

// How long a phase is, in seconds: what its ring is measured against.
function length(phase, lengths) {
    return phase === "break" ? lengths.breakSeconds : lengths.durationSeconds;
}

// Where the pomodoro goes when a phase is skipped or runs out: after focus a
// break runs at once; after a break focus waits, unstarted, to be started.
function next(phase, lengths) {
    if (phase === "work")
        return { phase: "break", remainingSeconds: lengths.breakSeconds, running: true, started: true };
    return { phase: "work", remainingSeconds: lengths.durationSeconds, running: false, started: false };
}
