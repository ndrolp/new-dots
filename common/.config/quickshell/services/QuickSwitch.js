.pragma library
.import "MonitorModes.js" as MonitorModes
.import "MonitorEntries.js" as MonitorEntries

// The quick switch's choices and the setup each one builds. Pure, no Quickshell; the panel and the
// toast for an unknown combination offer the same list and hand the choice to MonitorSetups.qml.

// A monitor's "only" choice. Identical monitors share a description, so their ports tell them apart.
function onlyLabel(entry, entries) {
    return MonitorEntries.hasTwin(entries, entry)
        ? entry.description + " (" + entry.port + ") only"
        : entry.description + " only";
}

// What to offer for these entries, in order: { kind, label }, and the `port` of an "only" choice.
function choices(entries) {
    return [{ kind: "extend", label: "Extend" }, { kind: "mirror", label: "Mirror" }].concat(
        entries.map(entry => ({ kind: "only", label: onlyLabel(entry, entries), port: entry.port })));
}

// Whether a monitor is copying another. Such a monitor has no bar of its own.
function mirroring(entries, port) {
    const entry = MonitorEntries.find(entries, port);
    return entry !== undefined && !entry.disabled && !!entry.mirror;
}

// Where P goes from `index` in a list of `count`.
function next(index, count) {
    return count > 0 ? (index + 1) % count : 0;
}

// On with its own picture, as it last was; what it never had comes out automatic. A mirror's own
// mode and position say what it's copying, so what it last was is under `arrangement`.
function turnedBackOn(entry, modes) {
    const last = entry.mirror ? entry.arrangement || {} : entry;
    const on = Object.assign({}, entry, {
        mode: MonitorModes.modeOrHighest(last.mode, modes),
        position: last.position,
        scale: MonitorEntries.scaleOf(last),
        transform: entry.transform || 0,
        disabled: false,
        mirror: ""
    });
    delete on.arrangement;
    return on;
}

// Every monitor on, where it last was; closing up places one with no place yet past the others.
function extended(entries, modesOf) {
    return MonitorEntries.closedUp(entries.map(entry => turnedBackOn(entry, modesOf(entry.port))));
}

// Monitors copying `name`, each at its own preferred mode. Scale 1 fits any mode, and what the monitor
// was goes under `arrangement`, which setups.lua ignores, for Extend to bring back.
function copying(entry, name) {
    if (entry.mirror === name)
        return entry;
    return Object.assign({}, entry, {
        mode: "preferred",
        scale: 1,
        disabled: false,
        mirror: name,
        arrangement: { mode: entry.mode, position: entry.position, scale: entry.scale }
    });
}

// A monitor can't copy a copy, so one with no picture of its own can't be the one copied.
function mirrored(entries, focusedPort) {
    const focused = MonitorEntries.find(entries, focusedPort);
    const source = focused !== undefined && MonitorEntries.hasOwnPicture(focused)
        ? focused : entries.filter(MonitorEntries.hasOwnPicture)[0];
    if (source === undefined)
        return entries;
    const name = MonitorEntries.hasTwin(entries, source) ? source.port : source.description;
    return entries.map(entry => entry.port === source.port ? entry : copying(entry, name));
}

// The others keep where they were, and so does `port`, so Extend finds everything in place.
function only(entries, port, modesOf) {
    if (MonitorEntries.find(entries, port) === undefined)
        return entries;
    return extended(entries, modesOf).map(entry => Object.assign({}, entry, { disabled: entry.port !== port }));
}

// The entries a choice from `choices` leaves the monitors in, for MonitorSetups.apply. `focusedPort`
// is the monitor Mirror copies; `modesOf(port)` gives a monitor's modes as MonitorSetups.modesOf does.
function entriesFor(choice, entries, focusedPort, modesOf) {
    if (choice.kind === "mirror")
        return mirrored(entries, focusedPort);
    if (choice.kind === "only")
        return only(entries, choice.port, modesOf);
    return extended(entries, modesOf);
}
