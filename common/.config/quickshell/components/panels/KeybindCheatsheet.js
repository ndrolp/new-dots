.pragma library

// The keybind cheatsheet's model: pure logic, no Quickshell. It turns the
// bindings from `hyprctl binds -j` into entries grouped by modifier.

// Hyprland's modifier mask bits, in the order a combo is written.
const modifiers = [
    { bit: 64, name: "SUPER" },
    { bit: 4, name: "CTRL" },
    { bit: 8, name: "ALT" },
    { bit: 1, name: "SHIFT" }
];

// "SUPER + SHIFT" for mask 65; empty for a binding without modifiers.
function modifierLabel(modmask) {
    return modifiers.filter(modifier => (modmask & modifier.bit) !== 0)
        .map(modifier => modifier.name).join(" + ");
}

const mouseButtons = {
    "mouse:272": "Left click",
    "mouse:273": "Right click",
    "mouse:274": "Middle click",
    "mouse_up": "Scroll up",
    "mouse_down": "Scroll down"
};

function keyLabel(key) {
    const name = String(key || "");
    return mouseButtons[name] || (name.length === 1 ? name.toUpperCase() : name);
}

// The bindings as [{ modifiers, entries: [{ keys, description }] }]: one group
// per modifier combination, ordered by mask with unmodified keys last, each
// keeping the configured order. A binding registered twice is listed once.
function groups(binds) {
    const byMask = {};
    const seen = {};

    for (const bind of binds || []) {
        const modifiers = modifierLabel(bind.modmask);
        const key = keyLabel(bind.key);
        const keys = modifiers === "" ? key : modifiers + " + " + key;
        const description = String(bind.description || "");
        if (seen[keys + "\n" + description])
            continue;
        seen[keys + "\n" + description] = true;

        if (!byMask[bind.modmask])
            byMask[bind.modmask] = { mask: bind.modmask, modifiers: modifiers || "No modifier",
                entries: [] };
        byMask[bind.modmask].entries.push({ keys: keys, description: description });
    }

    return Object.values(byMask)
        .sort((a, b) => (a.mask === 0) - (b.mask === 0) || a.mask - b.mask)
        .map(group => ({ modifiers: group.modifiers, entries: group.entries }));
}

// The groups read from the text `hyprctl binds -j` printed; none when it
// isn't a binding list.
function fromOutput(text) {
    try {
        const binds = JSON.parse(text);
        return Array.isArray(binds) ? groups(binds) : [];
    } catch (error) {
        return [];
    }
}

// The groups narrowed to entries where every word of `query` appears in the
// combo or the description, ignoring case and "+"; empty groups are dropped.
function filter(groups, query) {
    const words = String(query || "").toLowerCase().split(/[\s+]+/).filter(word => word !== "");

    return groups.map(group => ({
        modifiers: group.modifiers,
        entries: group.entries.filter(entry => {
            const text = (entry.keys + " " + entry.description).toLowerCase();
            return words.every(word => text.includes(word));
        })
    })).filter(group => group.entries.length > 0);
}
