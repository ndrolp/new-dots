.pragma library
.import "MonitorArrangement.js" as MonitorArrangement
.import "MonitorModes.js" as MonitorModes

// Monitor setups: what `hyprctl monitors all -j` means as one, the changes Displays and the quick
// switch make to one, and the saved file Hyprland reads (see docs/adr/0002 and
// hypr/modules/monitors/setups.lua, which applies it). Pure, no Quickshell. An entry is one monitor
// of a setup, in the saved format: { description, port, mode, position, scale, transform, disabled,
// mirror } and whatever else the file holds for it, which is kept and written back.

// Also in setups.lua, which can't share code with this.
function isLaptopPort(port) {
    return /^(eDP|LVDS|DSI)-/.test(port);
}

// The monitors that count: the same rule as split_by_lid in setups.lua. With a closed lid and an
// external monitor the laptop screen is no part of the combination, so it's no part of a setup.
function presentMonitors(monitors, lidClosed) {
    const present = monitors.filter(monitor => !(lidClosed && isLaptopPort(monitor.name)));
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

// The monitors can have changed after one of these Hyprland events.
function changesMonitors(eventName) {
    return /^(monitoradded|monitorremoved|configreloaded)/.test(eventName);
}

// Each monitor's saved entry, by port: the same pairing as `pair` in setups.lua, which applies it. By
// description and port, then by description, and an entry goes to one monitor only, so identical
// monitors that changed ports can't end up showing what Hyprland didn't apply.
function paired(monitors, saved) {
    const pairs = {};
    const taken = [];
    function take(accepts) {
        monitors.filter(monitor => pairs[monitor.name] === undefined).forEach(monitor => {
            const index = saved.findIndex((entry, at) => !taken[at] && accepts(monitor, entry));
            if (index !== -1) {
                taken[index] = true;
                pairs[monitor.name] = saved[index];
            }
        });
    }
    take((monitor, entry) => entry.description === monitor.description && entry.port === monitor.name);
    take((monitor, entry) => entry.description === monitor.description);
    return pairs;
}

// Whether another of these monitors or entries has the same description, so only ports tell them apart.
function hasTwin(list, one) {
    return list.filter(other => other.description === one.description).length > 1;
}

// A mirror names the monitor it copies by description, or by port between identical monitors.
function mirrorName(monitor, monitors) {
    const copied = monitors.filter(other => String(other.id) === String(monitor.mirrorOf))[0];
    if (copied === undefined)
        return "";
    return hasTwin(monitors, copied) ? copied.name : copied.description;
}

// A monitor that is off says little about itself, so what it would come back with is the saved
// entry's.
function entryFrom(monitor, monitors, savedEntry) {
    const entry = Object.assign({}, savedEntry, {
        description: monitor.description,
        port: monitor.name,
        disabled: monitor.disabled === true,
        mirror: mirrorName(monitor, monitors)
    });
    if (entry.disabled)
        return entry;

    entry.mode = MonitorModes.modeText({ width: monitor.width, height: monitor.height, refresh: monitor.refreshRate });
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
    const pairs = paired(present, saved);
    return present.map(monitor => entryFrom(monitor, present, pairs[monitor.name]));
}

function modesOf(monitors, port) {
    const monitor = monitors.filter(candidate => candidate.name === port)[0];
    return monitor !== undefined ? MonitorModes.parsedModes(monitor.availableModes || []) : [];
}

// A monitor's number: the one Identify flashes on it. 0 for a port that isn't one of them.
function numberOf(entries, port) {
    return entries.findIndex(entry => entry.port === port) + 1;
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

// An imported setup can say "auto" for a scale.
function scaleOf(entry) {
    const scale = Number(entry.scale);
    return scale > 0 ? scale : 1;
}

// Null for what isn't a place, like the "auto" and "auto-left" of an imported setup.
function positionOf(entry) {
    const found = /^(-?\d+)x(-?\d+)$/.exec(entry.position || "");
    return found !== null ? { x: Number(found[1]), y: Number(found[2]) } : null;
}

function rectangle(entry, position) {
    const mode = MonitorModes.parsedMode(entry.mode);
    const sideways = (entry.transform || 0) % 2 === 1;
    const width = Math.round((mode !== null ? mode.width : 1920) / scaleOf(entry));
    const height = Math.round((mode !== null ? mode.height : 1080) / scaleOf(entry));
    return {
        id: entry.port,
        x: position.x,
        y: position.y,
        width: sideways ? height : width,
        height: sideways ? width : height
    };
}

// The monitors with a place of their own, as MonitorArrangement's rectangles in logical pixels. One
// with no place yet goes past the others, which is also where the first change writes it.
function rectangles(entries) {
    const own = entries.filter(hasOwnPicture);
    const rects = own.filter(entry => positionOf(entry) !== null)
        .map(entry => rectangle(entry, positionOf(entry)));
    own.filter(entry => positionOf(entry) === null).forEach(entry => {
        rects.push(rectangle(entry, MonitorArrangement.nextSlot(rects)));
    });
    return own.map(entry => rects.filter(rect => rect.id === entry.port)[0]);
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
        mode: MonitorModes.modeText(mode),
        scale: cleanScale(width, height, scaleOf(entry))
    }), port);
}

function withRefresh(entries, port, refresh) {
    const mode = MonitorModes.parsedMode(find(entries, port).mode);
    return withEntry(entries, port, { mode: MonitorModes.modeText(Object.assign(mode, { refresh: refresh })) });
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
    const list = withEntry(entries, port, { disabled: false, mode: MonitorModes.modeOrHighest(entry.mode, modes),
        scale: scaleOf(entry), transform: entry.transform || 0 });
    return closedUp(atTheEnd(list, port));
}

// A combination is the monitors that make it, regardless of port or order.
function combination(entries) {
    return entries.map(entry => entry.description).sort().join("\n");
}

// The saved file's text from how loading it went, "loaded", "missing" or anything else: null for a
// file that isn't there and undefined for one that couldn't be loaded, which isn't the same thing.
function loadedText(outcome, text) {
    if (outcome === "loaded")
        return text;
    return outcome === "missing" ? null : undefined;
}

// The saved file's data from `loadedText`. A file that isn't there has no setups; one that can't be
// read is null, so nothing overwrites it.
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

// `data` with the setups of `key`, a combination, gone. Every copy, as Hyprland takes the first match.
function withoutSetup(data, key) {
    return Object.assign({}, data, { setups: data.setups.filter(setup => combination(setup.monitors) !== key) });
}

function setupName(setup, label) {
    return setup.monitors.map(label).sort().join(" + ");
}

function maker(entry) {
    return entry.description.split(" ")[0];
}

// What's really saved: a change being tried out is in the file, but isn't saved until Keep.
function keptData(data) {
    return data.unkept !== undefined ? parsedFile(data.unkept.before) || { setups: [] } : data;
}

// The saved setups as a list to show: { combination, name, monitors }, named after their monitors'
// makers, like "AOC + Philips". Setups that would share a name go by their full descriptions.
function listedSetups(data) {
    const setups = keptData(data).setups;
    const names = setups.map(setup => setupName(setup, maker));
    return setups.map((setup, index) => ({
        combination: combination(setup.monitors),
        name: names.filter(name => name === names[index]).length > 1
            ? setupName(setup, entry => entry.description)
            : names[index],
        monitors: setup.monitors
    }));
}
