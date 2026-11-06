.pragma library
.import "MonitorSetup.js" as MonitorSetup

// A change of monitors waiting for Keep or Revert, however it was made. Pure, no Quickshell;
// MonitorSetups.qml carries out each step: { state, text, remove, apply } is the next state, the text
// to write to the saved file (null for none), whether to remove the file, and whether to ask
// Hyprland to apply it once that's done. Times are Date.now() milliseconds, passed in as `now`.
//
// Hyprland only applies what's in the saved file, so the change has to be in it while it's tried
// out. The file also holds what to go back to, as `unkept`, written in the same atomic write: if the
// shell stops during a countdown, it finds that when it starts and reverts, so only Keep ever saves.

const countdownSeconds = 15;

// - before: the saved file's text when the change began, null when there was no file.
// - previous: the entries the monitors were in then.
// - trying: the entries being tried out.
const idle = Object.freeze({ phase: "idle", endsAt: 0, before: null, previous: [], trying: [] });

function counting(state) {
    return state.phase === "counting";
}

// Revert has put the arrangement back, and the file still has to be.
function restoring(state) {
    return state.phase === "restoring";
}

function step(state, text, apply) {
    return { state: state, text: text, remove: false, apply: apply };
}

function fileWith(before, entries, previous) {
    const data = MonitorSetup.parsedFile(before);
    const replaced = entries.length > 0 ? MonitorSetup.withSetup(data, entries) : data;
    return MonitorSetup.serialized(previous !== undefined
        ? Object.assign({}, replaced, { unkept: { before: before, monitors: previous } })
        : replaced);
}

// Trying out `entries`, with the file as `fileText` and the monitors as `live`. A change during a
// countdown restarts it, and Revert still goes back to where the first change began.
function changed(state, fileText, live, entries, now) {
    const before = counting(state) ? state.before : fileText;
    const previous = counting(state) ? state.previous : live;
    const next = { phase: "counting", endsAt: now + countdownSeconds * 1000, before: before,
        previous: previous, trying: entries };
    return step(next, fileWith(before, entries, previous), true);
}

function secondsLeft(state, now) {
    return counting(state) ? Math.max(0, Math.ceil((state.endsAt - now) / 1000)) : 0;
}

function expired(state, now) {
    return counting(state) && now >= state.endsAt;
}

// Keep: the setup is saved, and nothing is left to go back to.
function kept(state) {
    return step(idle, fileWith(state.before, state.trying), false);
}

// Revert, first half: `previous` goes through the file like any change, because a setup that was
// never saved has nowhere else to come from.
function reverted(state) {
    const next = Object.assign({}, state, { phase: "restoring", endsAt: 0 });
    return step(next, fileWith(state.before, state.previous, state.previous), true);
}

// Revert, second half, once Hyprland has read that: the file goes back to exactly what it was. No
// file means Hyprland stands aside, which an empty one wouldn't.
function restored(state) {
    return { state: idle, text: state.before, remove: state.before === null, apply: false };
}

// The countdown a shell that stopped left in the file, as a state to revert, or null.
function interrupted(fileText) {
    const data = MonitorSetup.parsedFile(fileText);
    if (data === null || data.unkept === undefined)
        return null;
    return { phase: "counting", endsAt: 0, before: data.unkept.before, previous: data.unkept.monitors,
        trying: [] };
}

function parsedUnkept(fileText) {
    const data = MonitorSetup.parsedFile(fileText);
    return data !== null && data.unkept !== undefined ? data.unkept : null;
}
