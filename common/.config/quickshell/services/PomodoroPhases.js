.pragma library

// The pomodoro's phases (Pomodoro.qml): "work", a focus phase as long as the
// chosen duration, then "break". `lengths` is { durationSeconds,
// breakSeconds }. Pure, no Quickshell.

// What each phase is: its `name`, the colorscheme colour it is drawn in
// (`colour`, a Theme.qml colour name), which of `lengths` it lasts
// (`length`) and what the pomodoro popup outside a capsule says while it
// runs and while it is paused (`running`, `paused`).
const phases = {
    work: { name: "Focus", colour: "red", length: "durationSeconds",
        running: "Focus session in progress", paused: "Timer paused" },
    break: { name: "Break", colour: "green", length: "breakSeconds",
        running: "Break in progress", paused: "Break paused" }
};

// A phase's entry in the table above; anything but "break" is focus.
function phase(name) {
    return name === "break" ? phases.break : phases.work;
}

// How long a phase is, in seconds: what its ring is measured against.
function length(name, lengths) {
    return lengths[phase(name).length];
}

// Where the pomodoro goes when a phase is skipped or runs out: after focus a
// break runs at once; after a break focus waits, unstarted, to be started.
function next(name, lengths) {
    if (name === "work")
        return { phase: "break", remainingSeconds: lengths.breakSeconds, running: true, started: true };
    return { phase: "work", remainingSeconds: lengths.durationSeconds, running: false, started: false };
}

// What the pomodoro popup outside a capsule says under the time left: the
// phase that runs or is paused, or, before a pomodoro starts, to choose its
// focus duration.
function status(name, running, started) {
    if (!started)
        return "Choose a focus duration";
    return running ? phase(name).running : phase(name).paused;
}
