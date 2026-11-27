.pragma library

// How Hyprland draws windows, as the Windows section of the settings saves it. Pure, no Quickshell;
// WindowAppearance.qml writes the file and asks Hyprland to apply it. Hyprland owns the file
// (hypr/modules/appearence/windows.lua), as it owns monitor setups
// (docs/adr/0002-hyprland-owns-monitor-setups.md), and reads it by the same rules as valuesFrom.

// One entry per setting, by its key in the file: what it takes and its default. Kinds: "integer"
// and "number" between min and max, "boolean". Keep them in step with SETTINGS in windows.lua.
const settings = {
    gaps_in: { kind: "integer", min: 0, max: 30, default: 5 },
    gaps_out: { kind: "integer", min: 0, max: 60, default: 10 },
    // 0 hides the border; its colours stay the colorscheme's.
    border_size: { kind: "integer", min: 0, max: 6, default: 2 },
    rounding: { kind: "integer", min: 0, max: 24, default: 5 },
};

// How Hyprland is asked to apply the saved file: only that module, not a full reload.
const applyCommand = ["hyprctl", "eval", 'require("modules.appearence.windows").apply()'];

function valid(setting, value) {
    if (setting.kind === "boolean")
        return typeof value === "boolean";
    if (typeof value !== "number" || !isFinite(value) || value < setting.min || value > setting.max)
        return false;
    return setting.kind !== "integer" || Number.isInteger(value);
}

function defaults() {
    const values = {};
    for (const key in settings)
        values[key] = settings[key].default;
    return values;
}

// Every setting's value, by key, from the saved file's text: the saved one where it's usable, its
// default otherwise. No text (no file) or text that isn't a JSON object gives every default.
function valuesFrom(text) {
    let saved = null;
    try {
        saved = typeof text === "string" ? JSON.parse(text) : null;
    } catch (e) {
        saved = null;
    }
    if (saved === null || typeof saved !== "object" || Array.isArray(saved))
        saved = {};
    const values = {};
    for (const key in settings)
        values[key] = valid(settings[key], saved[key]) ? saved[key] : settings[key].default;
    return values;
}

// `values` with `key` set to `value`, kept in its range (and whole, for an integer).
function withValue(values, key, value) {
    const setting = settings[key];
    const next = Object.assign({}, values);
    if (setting.kind === "boolean") {
        next[key] = !!value;
    } else {
        const number = setting.kind === "integer" ? Math.round(value) : Number(value);
        next[key] = Math.min(setting.max, Math.max(setting.min, number));
    }
    return next;
}

// What to write to the saved file for `values`.
function fileText(values) {
    return JSON.stringify(values, null, 2) + "\n";
}
