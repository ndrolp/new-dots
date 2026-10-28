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
// below, which return the next state.
// - failureHint: why night light went off on its own ("" otherwise), shown
//   under the control center toggle.
// - hyprsunset: what NightLight.qml makes the process do: "running" (start it
//   if it isn't), "stopping" (stop it and wait for it to exit) or "stopped".
//   Turning night light back on while the old hyprsunset is still exiting
//   keeps it "stopping" until it exits, then starts it again.
// It isn't saved, so every shell start begins with it off.
const off = { on: false, failureHint: "", hyprsunset: "stopped" };

// The control center toggle: turning it on tries hyprsunset afresh, so an
// old hint goes.
function toggled(state) {
    const on = !state.on;
    let hyprsunset = state.hyprsunset;
    if (on && hyprsunset === "stopped")
        hyprsunset = "running";
    else if (!on && hyprsunset === "running")
        hyprsunset = "stopping";
    return { on: on, failureHint: "", hyprsunset: hyprsunset };
}

// hyprsunset exited with `exitCode`. When it was asked to stop that is just
// it stopping, whatever the code, and it starts again if night light was
// turned back on meanwhile. Exiting on its own turns night light off and the
// hint says why.
function exited(state, exitCode) {
    if (state.hyprsunset === "stopping")
        return Object.assign({}, state, { hyprsunset: state.on ? "running" : "stopped" });
    if (!state.on)
        return state;
    return { on: false, failureHint: failureHint(exitCode), hyprsunset: "stopped" };
}

function failureHint(exitCode) {
    if (exitCode === 127)
        return "hyprsunset isn't installed, so night light can't turn on.";
    return "hyprsunset stopped, so night light turned off.";
}
