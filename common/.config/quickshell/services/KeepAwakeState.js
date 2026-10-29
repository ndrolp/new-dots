.pragma library

// Keep-awake: whether it is on, the selected duration and its countdown.
// Pure, no Quickshell; KeepAwake.qml carries the decisions out. Times are
// milliseconds since the epoch (Date.now()), passed in as `now`.

// The durations the popup offers, in minutes; 0 is "until turned off".
const durations = [
    { minutes: 0, label: "Until turned off" },
    { minutes: 30, label: "30 min" },
    { minutes: 60, label: "1 h" },
    { minutes: 120, label: "2 h" }
];

// Plain state, changed only through the functions below, which return the
// next state.
// - duration: the selected duration in minutes, 0 for "until turned off".
//   Turning keep-awake on from anywhere uses it.
// - endsAt: when a timed keep-awake runs out, 0 while there is no countdown.
// - ended: keep-awake has just turned off because its countdown ran out, so
//   KeepAwake.qml sends the end notification. Only that one change says so;
//   turning it off by hand never does.
// Neither is saved, so every shell start begins off and "until turned off".
const off = { on: false, duration: 0, endsAt: 0, ended: false };

function endsAt(duration, now) {
    return duration > 0 ? now + duration * 60 * 1000 : 0;
}

// Turning keep-awake on starts the selected duration's countdown; turning it
// off clears it.
function toggled(state, now) {
    const on = !state.on;
    return { on: on, duration: state.duration, endsAt: on ? endsAt(state.duration, now) : 0, ended: false };
}

// Selecting `duration` (minutes, 0 for "until turned off"). While keep-awake
// is on its countdown restarts from it, or stops for "until turned off".
function durationChosen(state, duration, now) {
    return { on: state.on, duration: duration, endsAt: state.on ? endsAt(duration, now) : 0, ended: false };
}

// Whether a countdown is running.
function timed(state) {
    return state.on && state.endsAt !== 0;
}

// Time passing: when the countdown has run out keep-awake turns off and
// says it ended. The selected duration stays for the next time it turns on.
function ticked(state, now) {
    if (!timed(state) || now < state.endsAt)
        return Object.assign({}, state, { ended: false });
    return { on: false, duration: state.duration, endsAt: 0, ended: true };
}

// Sent when a timed keep-awake runs out.
const endedNotificationCommand = [
    "notify-send", "-a", "Keep-awake", "-u", "normal",
    "Keep-awake ended", "The PC can go idle and sleep again."
];

// Whole seconds left on the countdown, rounded up; 0 without one.
function secondsLeft(state, now) {
    if (!state.on || state.endsAt === 0)
        return 0;
    return Math.max(0, Math.ceil((state.endsAt - now) / 1000));
}

// `seconds` left as the popup shows it: "29:59", or "1:59:59" from an hour.
function timeLeftLabel(seconds) {
    const hours = Math.floor(seconds / 3600);
    const minutes = Math.floor(seconds % 3600 / 60);
    const secs = seconds % 60;
    const pad = n => (n < 10 ? "0" : "") + n;
    if (hours > 0)
        return hours + ":" + pad(minutes) + ":" + pad(secs);
    return minutes + ":" + pad(secs);
}
