.pragma library

// The pomodoro's ring, inside a capsule (PomodoroRingView.qml) and on its
// live element at rest: how much of it is drawn and in which colour.

// How much of the ring is drawn: the share of the phase still left, from 1
// when it starts to 0 when it ends. A phase shortened below the time left
// draws a full ring.
function fraction(remaining, total) {
    if (!(total > 0))
        return 0;
    return Math.max(0, Math.min(1, remaining / total));
}

// The phase's colour from the colorscheme's colours (Theme.qml): work is
// red, a break green.
function phaseColor(phase, colours) {
    return phase === "break" ? colours.green : colours.red;
}

// The phase's name, shown under the time left.
function phaseName(phase) {
    return phase === "break" ? "Break" : "Focus";
}
