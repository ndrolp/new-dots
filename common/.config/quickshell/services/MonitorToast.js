.pragma library

// When the toasts about monitors come up. Pure, no Quickshell; MonitorSetups.qml carries it out.
//
// - combination: the combination last read, so only a new one counts. Nothing is read while locked,
//   so a monitor plugged in then is new at the first reading after unlock.
// - offering: the unknown combination's toast is up.
const idle = Object.freeze({ combination: "", offering: false });

// The shell was reloaded: `combination` was already offered, if it needed to be.
function restored(combination) {
    return { combination: combination, offering: false };
}

// The monitors were read as `combination`, which `known` says has a saved setup. An offer stays until
// the combination is saved, changes or the toast is dismissed; ignoring it saves nothing.
function afterReading(state, combination, known, locked) {
    if (locked)
        return state;
    return {
        combination: combination,
        offering: !known && combination !== "" && (state.offering || combination !== state.combination)
    };
}

function dismissed(state) {
    return Object.assign({}, state, { offering: false });
}

// Reads what Hyprland left beside the saved file at `path`: "unreadable" or "readable", then the
// monitors in `.fallback`. A `.bad` file is news only once, and it's kept as a backup whatever happens,
// so it's moved aside as it's read: that holds across restarts, and a new bad file is news again.
function noticesCommand(path) {
    return ["sh", "-c",
        'if mv -f -- "$1.bad" "$1.bad.told" 2>/dev/null; then echo unreadable; else echo readable; fi; '
        + 'cat -- "$1.fallback" 2>/dev/null', "sh", path];
}

const unreadableMessage = "The saved monitor setups can't be read, so the automatic setup is in use. The bad file is kept beside them.";

function fallbackMessage(monitors) {
    return monitors.join(", ") + (monitors.length === 1 ? " is" : " are")
        + " on the automatic setup: the saved mode is gone.";
}

// What `noticesCommand` printed: { message, told }. `message` is what to tell, "" for nothing, and
// `told` the monitors already told about, to pass in next time. A monitor that's no longer listed
// drops out, so it's news again the next time it falls back.
function noticed(text, told) {
    const lines = text.split("\n").filter(line => line !== "");
    const fellBack = lines.slice(1);
    const toldBefore = told.split("\n");
    const fresh = fellBack.filter(monitor => toldBefore.indexOf(monitor) === -1);
    const messages = [];
    if (lines[0] === "unreadable")
        messages.push(unreadableMessage);
    if (fresh.length > 0)
        messages.push(fallbackMessage(fresh));
    return { message: messages.join(" "), told: fellBack.join("\n") };
}
