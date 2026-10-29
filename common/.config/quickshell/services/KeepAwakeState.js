.pragma library

// Keep-awake: whether it is on, the selected duration and its countdown.
// Pure, no Quickshell; KeepAwake.qml carries the decisions out. Times are
// milliseconds since the epoch (Date.now()), passed in as `now`.

// The duration that never runs out: keep-awake stays on until turned off.
const untilTurnedOff = 0;

// The durations the popup offers, in minutes.
const durations = [
    { minutes: untilTurnedOff, label: "Until turned off" },
    { minutes: 30, label: "30 min" },
    { minutes: 60, label: "1 h" },
    { minutes: 120, label: "2 h" }
];

// Plain state, changed only through the functions below, which return the
// next state (ticked along with whether the countdown ended).
// - duration: the selected duration in minutes, or untilTurnedOff. Turning
//   keep-awake on from anywhere uses it.
// - endsAt: when a timed keep-awake runs out, 0 while there is no countdown.
// Neither is saved, so every shell start begins off and "until turned off".
const off = { on: false, duration: untilTurnedOff, endsAt: 0 };

// The cups that show keep-awake: filled while on, an outline while off.
const cups = Object.freeze({ on: "󰅶", off: "󰛊" });

function cup(on) {
    return on ? cups.on : cups.off;
}

function endsAt(duration, now) {
    return duration !== untilTurnedOff ? now + duration * 60 * 1000 : 0;
}

// Turning keep-awake on starts the selected duration's countdown; turning it
// off clears it.
function toggled(state, now) {
    const on = !state.on;
    return { on: on, duration: state.duration, endsAt: on ? endsAt(state.duration, now) : 0 };
}

// Selecting `duration` (minutes, or untilTurnedOff). While keep-awake is on
// its countdown restarts from it, or stops for untilTurnedOff.
function durationChosen(state, duration, now) {
    return { on: state.on, duration: duration, endsAt: state.on ? endsAt(duration, now) : 0 };
}

// Whether a countdown is running.
function timed(state) {
    return state.on && state.endsAt !== 0;
}

// Time passing, as `{ state, ended }`: when the countdown has run out
// keep-awake turns off and `ended` is true, so KeepAwake.qml sends the end
// notification. Only that tick ends it; turning it off by hand never does.
// The selected duration stays for the next time it turns on.
function ticked(state, now) {
    if (!timed(state) || now < state.endsAt)
        return { state: state, ended: false };
    return { state: { on: false, duration: state.duration, endsAt: 0 }, ended: true };
}

// Sent when a timed keep-awake runs out.
const endedNotificationCommand = [
    "notify-send", "-a", "Keep-awake", "-u", "normal",
    "Keep-awake ended", "The PC can go idle and sleep again."
];

// Whole seconds left on the countdown, rounded up; 0 without one.
function secondsLeft(state, now) {
    if (!timed(state))
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

// What the OSD says when the keybind toggles keep-awake: off, on, or on with
// the selected duration as the popup names it ("Keep-awake on · 1 h").
function osdLabel(on, duration) {
    if (!on)
        return "Keep-awake off";
    const chosen = durations.find(d => d.minutes === duration);
    return duration !== untilTurnedOff && chosen ? "Keep-awake on · " + chosen.label : "Keep-awake on";
}
