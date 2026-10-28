.pragma library

// Night light: how warm hyprsunset makes the screen and when it runs. Pure,
// no Quickshell; NightLight.qml carries the decisions out.

// The temperatures the slider offers, in kelvin: from warm to hyprsunset's
// neutral 6000 K, in steps of a hundred.
const minTemperature = 2500;
const maxTemperature = 6000;
const temperatureStep = 100;
const defaultTemperature = 4000;

// `value` (the saved temperature or the slider's) as a temperature night
// light uses: in range and on a step; the default when it isn't a number.
function temperature(value) {
    if (typeof value !== "number" || isNaN(value))
        return defaultTemperature;
    const stepped = Math.round(value / temperatureStep) * temperatureStep;
    return Math.max(minTemperature, Math.min(maxTemperature, stepped));
}

// Runs hyprsunset at `kelvin` until it is stopped; stopping it gives the
// screen its colours back. It runs through sh, which exits 127 when it can't
// find hyprsunset (see exited).
function startCommand(kelvin) {
    return ["sh", "-c", "exec hyprsunset -t \"$1\"", "sh", String(kelvin)];
}

// Moves the running hyprsunset to `kelvin` through its IPC, so the slider
// changes the screen live without restarting it.
function temperatureCommand(kelvin) {
    return ["hyprctl", "hyprsunset", "temperature", String(kelvin)];
}

// Whether night light is on: plain state, changed only through the functions
// below, which return the next state. hyprsunset runs exactly while `on`.
// - failureHint: why night light went off on its own ("" otherwise), shown
//   under the control center toggle.
// It isn't saved, so every shell start begins with it off.
const off = { on: false, failureHint: "" };

// The control center toggle: turning it on tries hyprsunset afresh, so an
// old hint goes.
function toggled(state) {
    return { on: !state.on, failureHint: "" };
}

// hyprsunset exited with `exitCode`. Once night light is off that is just it
// stopping; while it is on, night light goes off and the hint says why.
function exited(state, exitCode) {
    if (!state.on)
        return state;
    return { on: false, failureHint: failureHint(exitCode) };
}

function failureHint(exitCode) {
    if (exitCode === 127)
        return "hyprsunset isn't installed, so night light can't turn on.";
    return "hyprsunset stopped, so night light turned off.";
}
