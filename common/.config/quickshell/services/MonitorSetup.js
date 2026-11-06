.pragma library
.import "MonitorArrangement.js" as MonitorArrangement
.import "MonitorModes.js" as MonitorModes

// Monitor setups: what `hyprctl monitors all -j` means as one, the changes Displays and the quick
// switch make to one, and the saved file Hyprland reads (see docs/adr/0002 and
// hypr/modules/monitors/setups.lua, which applies it). Pure, no Quickshell. An entry is one monitor
// of a setup, in the saved format: { description, port, mode, position, scale, transform, disabled,
// mirror } and whatever else the file holds for it, which is kept and written back.

function internal(monitor) {
    return /^(eDP|LVDS|DSI)-/.test(monitor.name);
}

// The monitors that count: the same rule as split_by_lid in setups.lua. With a closed lid and an
// external monitor the laptop screen is no part of the combination, so it's no part of a setup.
function presentMonitors(monitors, lidClosed) {
    const present = monitors.filter(monitor => !(lidClosed && internal(monitor)));
    return present.length > 0 ? present : monitors;
}

// What MonitorSetups.qml reads: the lid's state, if the machine has one, then hyprctl's JSON list.
function parsedReading(text) {
    const listAt = text.indexOf("[");
    if (listAt === -1)
        return null;
    try {
        const monitors = JSON.parse(text.slice(listAt));
        if (!Array.isArray(monitors))
            return null;
        return { lidClosed: text.slice(0, listAt).indexOf("closed") !== -1, monitors: monitors };
    } catch (error) {
        return null;
    }
}

function savedEntryFor(monitor, saved) {
    return saved.filter(entry => entry.description === monitor.description && entry.port === monitor.name)[0]
        || saved.filter(entry => entry.description === monitor.description)[0]
        || {};
}

// A mirror names the monitor it copies by description, or by port between identical monitors.
function mirrorName(monitor, monitors) {
    const copied = monitors.filter(other => String(other.id) === String(monitor.mirrorOf))[0];
    if (copied === undefined)
        return "";
    const twins = monitors.filter(other => other.description === copied.description);
    return twins.length > 1 ? copied.name : copied.description;
}

// A monitor that is off says little about itself, so what it would come back with is the saved
// entry's.
function entryFrom(monitor, monitors, saved) {
    const entry = Object.assign({}, savedEntryFor(monitor, saved), {
        description: monitor.description,
        port: monitor.name,
        disabled: monitor.disabled === true,
        mirror: mirrorName(monitor, monitors)
    });
    if (entry.disabled)
        return entry;

    entry.mode = MonitorModes.modeText(monitor.width, monitor.height, monitor.refreshRate);
    entry.position = monitor.x + "x" + monitor.y;
    entry.scale = monitor.scale;
    entry.transform = monitor.transform;
    if (entry.bitdepth === undefined && (monitor.currentFormat || "").indexOf("2101010") !== -1)
        entry.bitdepth = 10;
    return entry;
}

// The setup the monitors are in now, on top of the `saved` entries of their combination.
function entriesFrom(monitors, saved, lidClosed) {
    const present = presentMonitors(monitors, lidClosed);
    return present.map(monitor => entryFrom(monitor, present, saved));
}

function modesOf(monitors, port) {
    const monitor = monitors.filter(candidate => candidate.name === port)[0];
    return monitor !== undefined ? MonitorModes.parsedModes(monitor.availableModes || []) : [];
}

function hasOwnPicture(entry) {
    return !entry.disabled && !entry.mirror;
}

// False for a setup that would leave every screen dark. Monitors copying each other copy nothing.
function showsSomething(entries) {
    return entries.some(hasOwnPicture);
}

function sameEntries(a, b) {
    return JSON.stringify(a) === JSON.stringify(b);
}

function rectangle(entry) {
    const mode = MonitorModes.parsedMode(entry.mode);
    const position = /^(-?\d+)x(-?\d+)$/.exec(entry.position || "");
    const sideways = (entry.transform || 0) % 2 === 1;
    const scale = entry.scale || 1;
    const width = Math.round((mode !== null ? mode.width : 1920) / scale);
    const height = Math.round((mode !== null ? mode.height : 1080) / scale);
    return {
        id: entry.port,
        x: position !== null ? Number(position[1]) : 0,
        y: position !== null ? Number(position[2]) : 0,
        width: sideways ? height : width,
        height: sideways ? width : height
    };
}

// The monitors with a place of their own, as MonitorArrangement's rectangles in logical pixels.
function rectangles(entries) {
    return entries.filter(hasOwnPicture).map(rectangle);
}

function withEntry(entries, port, fields) {
    return entries.map(entry => entry.port === port ? Object.assign({}, entry, fields) : entry);
}

function placed(entries, rects) {
    return entries.map(entry => {
        const rect = rects.filter(candidate => candidate.id === entry.port)[0];
        return rect !== undefined ? Object.assign({}, entry, { position: rect.x + "x" + rect.y }) : entry;
    });
}

function find(entries, port) {
    return entries.filter(entry => entry.port === port)[0];
}

// `port` dropped at logical (x, y), snapped edge to edge.
function moved(entries, port, x, y) {
    if (rectangles(entries).filter(rect => rect.id === port).length === 0)
        return entries;
    return placed(entries, MonitorArrangement.snapped(rectangles(entries), port, x, y));
}

// After a change of size: the monitors around `port` make room or close up.
function rearranged(entries, port) {
    const rect = rectangles(entries).filter(candidate => candidate.id === port)[0];
    return rect !== undefined ? moved(entries, port, rect.x, rect.y) : entries;
}

function cleanScale(width, height, scale) {
    const nearest = MonitorModes.nearestScale(width, height, scale);
    return nearest !== null ? nearest : scale;
}

function withResolution(entries, port, modes, width, height) {
    const entry = find(entries, port);
    const current = MonitorModes.parsedMode(entry.mode);
    const mode = MonitorModes.afterResolution(modes, width, height, current !== null ? current.refresh : 0);
    return rearranged(withEntry(entries, port, {
        mode: MonitorModes.modeText(mode.width, mode.height, mode.refresh),
        scale: cleanScale(width, height, entry.scale || 1)
    }), port);
}

function withRefresh(entries, port, refresh) {
    const mode = MonitorModes.parsedMode(find(entries, port).mode);
    return withEntry(entries, port, { mode: MonitorModes.modeText(mode.width, mode.height, refresh) });
}

// `scale` as Hyprland will take it; the entry holds the scale that applies, not the one asked for.
function withScale(entries, port, scale) {
    const mode = MonitorModes.parsedMode(find(entries, port).mode);
    return rearranged(withEntry(entries, port, {
        scale: mode !== null ? cleanScale(mode.width, mode.height, scale) : scale
    }), port);
}

function withRotation(entries, port, transform) {
    return rearranged(withEntry(entries, port, { transform: transform }), port);
}

function mirrors(entry, copied) {
    return entry.mirror === copied.description || entry.mirror === copied.port;
}

function atTheEnd(entries, port) {
    const others = rectangles(entries).filter(rect => rect.id !== port);
    const slot = MonitorArrangement.nextSlot(others);
    return withEntry(entries, port, { position: slot.x + "x" + slot.y });
}

function closedUp(entries) {
    return placed(entries, MonitorArrangement.closed(rectangles(entries)));
}

// With `port` off, what was copying it has its own picture again, past the others.
function withoutPicture(entries, port) {
    const off = find(entries, port);
    const freed = entries.filter(entry => entry.port !== port && !entry.disabled && mirrors(entry, off));
    let list = withEntry(entries, port, { disabled: true, mirror: "" });
    freed.forEach(entry => {
        list = atTheEnd(withEntry(list, entry.port, { mirror: "" }), entry.port);
    });
    return list;
}

function canTurnOff(entries, port) {
    return find(entries, port) !== undefined && showsSomething(withoutPicture(entries, port));
}

// The last monitor stays on.
function turnedOff(entries, port) {
    return canTurnOff(entries, port) ? closedUp(withoutPicture(entries, port)) : entries;
}

// Back on past the others, with the mode it had, or the highest if it never had one.
function turnedOn(entries, port, modes) {
    const entry = find(entries, port);
    const highest = MonitorModes.highest(modes);
    const mode = entry.mode || (highest !== null
        ? MonitorModes.modeText(highest.width, highest.height, highest.refresh) : "preferred");
    const list = withEntry(entries, port, { disabled: false, mode: mode, scale: entry.scale || 1,
        transform: entry.transform || 0 });
    return closedUp(atTheEnd(list, port));
}

// A combination is the monitors that make it, regardless of port or order.
function combination(entries) {
    return entries.map(entry => entry.description).sort().join("\n");
}

// The saved file's data. A file that isn't there has no setups; one that can't be read is null, so
// nothing overwrites it. `text` is null for a file that isn't there.
function parsedFile(text) {
    if (text === null)
        return { setups: [] };
    try {
        const data = JSON.parse(text);
        return data !== null && Array.isArray(data.setups) ? data : null;
    } catch (error) {
        return null;
    }
}

function serialized(data) {
    return JSON.stringify(data, null, 2) + "\n";
}

// `data` with `entries` as the setup of their combination, leaving the others and whatever else the
// replaced setup held.
function withSetup(data, entries) {
    const key = combination(entries);
    const setups = data.setups.filter(setup => combination(setup.monitors) !== key);
    const replaced = data.setups.filter(setup => combination(setup.monitors) === key)[0];
    return Object.assign({}, data, {
        setups: setups.concat([Object.assign({}, replaced, { monitors: entries })])
    });
}

// The saved entries of the combination these monitors make, or none.
function savedEntries(data, monitors) {
    const key = combination(monitors);
    const setup = data.setups.filter(candidate => combination(candidate.monitors) === key)[0];
    return setup !== undefined ? setup.monitors : [];
}

// The saved setups as a list to show: { combination, name, monitors }, named after their monitors.
function listedSetups(data) {
    return data.setups.map(setup => ({
        combination: combination(setup.monitors),
        name: setup.monitors.map(entry => entry.description).sort().join(" + "),
        monitors: setup.monitors
    }));
}
