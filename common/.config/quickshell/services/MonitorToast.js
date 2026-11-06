.pragma library

// When the toasts about monitors come up. Pure, no Quickshell; MonitorSetups.qml carries it out.
//
// - combination: the combination last read, so only a new one counts. Nothing is read while locked,
//   so a monitor plugged in then is new at the first reading after unlock.
// - offering: the unknown combination's toast is up.
// - notice: what's being told about a failure, "" for nothing.
const idle = Object.freeze({ combination: "", offering: false, notice: "" });

// The shell was reloaded: `combination` was already offered, if it needed to be.
function restored(combination) {
    return Object.assign({}, idle, { combination: combination });
}

// The monitors were read as `combination`, which `known` says has a saved setup. An offer stays until
// the combination is saved, changes or the toast is dismissed; ignoring it saves nothing.
function afterReading(state, combination, known, locked) {
    if (locked)
        return state;
    return Object.assign({}, state, {
        combination: combination,
        offering: !known && combination !== "" && (state.offering || combination !== state.combination)
    });
}

function dismissed(state) {
    return Object.assign({}, state, { offering: false });
}

// `message` on the notice toast, after whatever it's already saying.
function withNotice(state, message) {
    if (state.notice === "")
        return Object.assign({}, state, { notice: message });
    if (state.notice.indexOf(message) !== -1)
        return state;
    return Object.assign({}, state, { notice: state.notice + " " + message });
}

function noticeDismissed(state) {
    return Object.assign({}, state, { notice: "" });
}

const unreadableMessage = "The saved monitor setups can't be read, so the automatic setup is in use. The bad file is kept beside them.";

function fallbackMessage(monitors) {
    return monitors.join(", ") + (monitors.length === 1 ? " is" : " are")
        + " on the automatic setup: the saved mode is gone.";
}

// What services/monitor-notices.sh printed: { message, told }. `message` is what to tell, "" for nothing, and
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
