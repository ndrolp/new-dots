.pragma library

// A monitor's resolutions, refresh rates and scales. Pure, no Quickshell.

// A monitor's refresh rate changes by less than this between modes that are the same rate rounded
// differently, like 60 and 59.95.
const sameRate = 0.5;

const scalePresets = [1, 1.25, 1.5, 1.6, 1.75, 2];

// "2560x1440@143.91Hz", "2560x1440@143.91" or "2560x1440" as { width, height, refresh }, with
// refresh 0 when there is none. null for what isn't a size, like "preferred".
function parsedMode(text) {
    const found = /^(\d+)x(\d+)(?:@([\d.]+))?/.exec(text || "");
    if (found === null)
        return null;
    return { width: Number(found[1]), height: Number(found[2]), refresh: Number(found[3] || 0) };
}

function parsedModes(texts) {
    return texts.map(parsedMode).filter(mode => mode !== null);
}

// A mode the way a monitor setup saves it, from { width, height, refresh }.
function modeText(mode) {
    return mode.width + "x" + mode.height + "@" + mode.refresh.toFixed(2);
}

// `mode` if it's a size, otherwise the highest of `modes`, or failing that a keyword Hyprland knows.
function modeOrHighest(mode, modes) {
    if (parsedMode(mode) !== null)
        return mode;
    const top = highest(modes);
    return top !== null ? modeText(top) : mode || "preferred";
}

// Each resolution once, largest first, as { width, height, label }.
function resolutions(modes) {
    const listed = [];
    modes.forEach(mode => {
        if (!listed.some(known => known.width === mode.width && known.height === mode.height))
            listed.push({ width: mode.width, height: mode.height, label: mode.width + "x" + mode.height });
    });
    return listed.sort((a, b) => b.width * b.height - a.width * a.height);
}

// The rates supported at a resolution, highest first.
function refreshRates(modes, width, height) {
    return modes.filter(mode => mode.width === width && mode.height === height)
        .map(mode => mode.refresh)
        .sort((a, b) => b - a);
}

// The mode a change of resolution lands on: the same rate if the resolution has it, otherwise its
// highest.
function afterResolution(modes, width, height, refresh) {
    const rates = refreshRates(modes, width, height);
    const kept = rates.filter(rate => Math.abs(rate - refresh) < sameRate)
        .sort((a, b) => Math.abs(a - refresh) - Math.abs(b - refresh))[0];
    return { width: width, height: height, refresh: kept !== undefined ? kept : rates[0] };
}

// The largest resolution at its top rate, or null with no modes.
function highest(modes) {
    if (modes.length === 0)
        return null;
    const largest = resolutions(modes)[0];
    return { width: largest.width, height: largest.height,
        refresh: refreshRates(modes, largest.width, largest.height)[0] };
}

// The presets, plus `current` when it isn't one, as an imported setup's can be.
function scaleChoices(current) {
    if (scalePresets.indexOf(current) !== -1)
        return scalePresets.slice();
    return scalePresets.concat([current]).sort((a, b) => a - b);
}

function scaleIsClean(width, height, scale) {
    return Number.isInteger(width / scale) && Number.isInteger(height / scale);
}

// The scale Hyprland lands on for `scale` at this resolution: the same search as applying a monitor
// rule (src/output/Monitor.cpp), in steps of 1/120 going up first, so the shell writes a scale that
// won't be refused. null when the search finds none.
function nearestScale(width, height, scale) {
    const steps = Math.round(scale * 120);
    if (scaleIsClean(width, height, steps / 120))
        return steps / 120;
    for (let i = 1; i < 90; i++) {
        if (scaleIsClean(width, height, (steps + i) / 120))
            return (steps + i) / 120;
        if (steps - i > 0 && scaleIsClean(width, height, (steps - i) / 120))
            return (steps - i) / 120;
    }
    return null;
}
