.pragma library
.import "MonitorSetup.js" as MonitorSetup

// A change of monitors waiting for Keep or Revert, however it was made. Pure, no Quickshell;
// MonitorSetups.qml carries out each step: { state, text, remove, apply } is the next state, the text
// to write to the saved file (null for none), whether to remove the file, and whether to ask
// Hyprland to apply it once that's done. Times are Date.now() milliseconds, passed in as `now`.
//
// Hyprland only applies what's in the saved file, so the change has to be in it while it's tried
// out. The file also holds what to go back to, as `unkept`, written in the same atomic write: if the
// shell stops during a countdown, Hyprland goes back by itself soon after it should have ended
// (hypr/modules/monitors/apply.lua), and a shell starting first finds `unkept` and reverts. Either way
// only Keep ever saves.

// TRIAL_MS in apply.lua is a few seconds more. Keep them in step.
const countdownSeconds = 15;

// How Hyprland is asked to read the saved file. See hypr/modules/monitors/apply.lua.
const applyCommand = ["hyprctl", "eval", 'require("modules.monitors.apply").apply_now()'];

// Whether `next` is worth trying out from `current`: not with another step running, and not if it
// would leave every screen dark or is what's already there.
function canTry(next, current, busy) {
    return !busy && next.length > 0 && MonitorSetup.showsSomething(next) && !MonitorSetup.sameEntries(next, current);
}

// Whether `next` is what the monitors are already in, with nothing else going on.
function canRemember(next, current, busy, waiting) {
    return !busy && !waiting && next.length > 0 && MonitorSetup.sameEntries(next, current);
}

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

// Revert, second half, once Hyprland has read that: the file goes back to exactly what it was, and
// a file that wasn't there goes again, so a change nobody kept leaves no trace. `failed` says Hyprland
// didn't take what it was given, which can leave some monitors changed, so it's asked again.
function restored(state, failed) {
    return { state: idle, text: state.before, remove: state.before === null, apply: failed };
}

// What to do with what hyprctl printed: { warning, step }, the warning to show, "" for none, and the
// next step, null if there isn't one. Anything but "ok" is why Hyprland didn't apply it. A trial it
// took just goes on counting down.
function afterAnswer(state, output) {
    const ok = output.trim() === "ok";
    const unfinished = counting(state) || restoring(state);
    return {
        warning: ok ? "" : ("Hyprland didn't apply the monitor setup: " + output.trim()).trim(),
        step: (unfinished && !ok) || restoring(state) ? restored(state, !ok) : null
    };
}

// Whether Hyprland has already gone back by itself, past its deadline or on a reload, so there's
// nothing left to answer: the file no longer has `unkept`. A file that can't be read says nothing.
function overtaken(state, fileText) {
    const data = MonitorSetup.parsedFile(fileText);
    return counting(state) && data !== null && data.unkept === undefined;
}

// Forget: the combination's setup leaves the file and Hyprland isn't asked, so the monitors stay as
// they are until the next time it detects them. Null, with nothing to write, if the file can't be
// read. Not for use during a countdown: Revert would put the file back as it was.
function forgotten(fileText, combination) {
    const data = MonitorSetup.parsedFile(fileText);
    return data !== null ? step(idle, MonitorSetup.serialized(MonitorSetup.withoutSetup(data, combination)), false) : null;
}

// Remembers what the monitors are already in, for a choice that changes nothing: there's nothing to
// try out, so no countdown. Null, with nothing to write, if the combination has a setup or the file
// can't be read.
function remembered(fileText, entries) {
    const data = MonitorSetup.parsedFile(fileText);
    if (data === null || MonitorSetup.savedEntries(data, entries).length > 0)
        return null;
    return step(idle, fileWith(fileText, entries), false);
}

// The countdown a shell that stopped left in the file, as a state to revert, or null.
function interrupted(fileText) {
    const data = MonitorSetup.parsedFile(fileText);
    if (data === null || data.unkept === undefined)
        return null;
    return { phase: "counting", endsAt: 0, before: data.unkept.before, previous: data.unkept.monitors,
        trying: [] };
}
