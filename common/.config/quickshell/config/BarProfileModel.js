.pragma library

// Bar profile model: pure logic over plain state, no Quickshell. Functions
// take state and return the changes to apply; they never mutate.
//
// State: { barProfiles, editingBarProfile, pendingProfile }. `barProfiles`
// are the saved profiles (appearance.json). The profile the settings panel
// edits and its pending changes live in memory only: `pendingProfile` is the
// edited profile with its pending changes, or null when there are none.
// Monitors drawing the edited profile show its pending changes; every other
// monitor draws its saved profile.

// Bar elements: every piece of the bar, one type. A profile stores them as
// `barElements`: { left: [...], center: [...], right: [...] }, each entry
// { id, enabled, joinPrevious?, options? }. Order within a zone is the order
// of the list.
const zoneNames = ["left", "center", "right"];

// Every bar element, in its default order; the first ones default to the
// zone in defaultElementZones, the rest to the right.
const elementIds = [
    "arch", "systemMonitor", "currentApp", "workspaces",
    "notifications", "recording", "media", "cava", "audio", "bluetooth", "tray",
    "network", "battery", "clock"
];
const defaultElementZones = {
    "arch": "left", "systemMonitor": "left", "currentApp": "left", "workspaces": "center"
};
// Elements that start disabled: in every default profile and wherever a
// profile does not list them yet.
const disabledElementIds = ["cava"];

// The options of the elements that have any, with their defaults.
const elementOptionDefaults = {
    "workspaces": {
        glyphsEnabled: false,
        glyphs: ["", "", "", "", "", "", "", "", "", "",
            "", "", "", "", "", "", "", "", "", ""],
        hideEmpty: false,
        appCountVisible: true
    },
    "notifications": { badgeVisible: true },
    "media": { titleVisible: true },
    // `color` names one of the theme's colors, so it follows the theme.
    "cava": { barCount: 12, barWidth: 3, color: "blue" },
    "audio": { meterVisible: true },
    "battery": { percentageVisible: true }
};

// What the options that can't take any value accept: a number's range
// ({ from, to }) or a choice's values ({ choices }). A stored value outside
// them is clamped, or falls back to the default.
const elementOptionLimits = {
    "cava": {
        barCount: { from: 6, to: 32 },
        barWidth: { from: 1, to: 8 },
        color: { choices: ["accent", "blue", "green", "yellow", "orange", "red", "purple", "text"] }
    }
};

function limitedOption(id, option, value, fallback) {
    const limit = (elementOptionLimits[id] || {})[option];

    if (!limit)
        return value;
    if (limit.choices)
        return limit.choices.indexOf(value) !== -1 ? value : fallback;
    if (typeof value !== "number" || isNaN(value))
        return fallback;
    return Math.max(limit.from, Math.min(limit.to, Math.round(value)));
}

// Bar elements with every element listed in its default zone and order,
// enabled unless listed in `disabledIds` or disabledElementIds, with `options` ({ id: options })
// over the default options.
function defaultBarElements(disabledIds, options) {
    const barElements = { left: [], center: [], right: [] };

    for (const id of elementIds) {
        barElements[defaultElementZones[id] || "right"].push({
            id: id,
            enabled: (disabledIds || []).indexOf(id) === -1
                && disabledElementIds.indexOf(id) === -1,
            options: (options || {})[id]
        });
    }

    return normalizeBarElements(barElements);
}

// Every setting a bar profile stores, with the value a profile that lacks it
// gets.
const defaultProfile = {
    barHeight: 32,
    horizontalPadding: 12,
    spacing: 8,
    radius: 8,
    workspaceButtonSize: 20,
    textSize: 14,
    archButtonHorizontalPadding: 6,
    activeWorkspaceHorizontalPadding: 6,
    pillVerticalPadding: 3,
    workspacePadding: 4,
    elementVerticalPadding: 5,
    pillsTransparent: false,
    transparentBarTopMargin: 0,
    transparentBarSlanted: false,
    groupRadius: 8,
    barTransparent: false,
    barTransparentBorder: false,
    barOpacity: 100,
    barElements: defaultBarElements([])
};

const profileKeys = Object.keys(defaultProfile);

// The profile that is edited first and that new monitors draw, if it exists.
const defaultBarProfile = "minimal";

// The bar profiles of a new appearance.json, in the current schema.
function defaultBarProfiles() {
    function profile(values, disabledIds, options) {
        return Object.assign(cloneValue(defaultProfile), values,
            { barElements: defaultBarElements(disabledIds, options) });
    }

    const compact = {
        barHeight: 30, horizontalPadding: 10, spacing: 4, radius: 6,
        workspaceButtonSize: 18, textSize: 13, archButtonHorizontalPadding: 5,
        activeWorkspaceHorizontalPadding: 5, pillVerticalPadding: 2, workspacePadding: 3
    };
    const compactOptions = { "workspaces": { hideEmpty: true, appCountVisible: false } };

    return {
        "minimal": profile(Object.assign({}, compact, {
            pillsTransparent: true, transparentBarTopMargin: 6, barTransparent: true,
            barTransparentBorder: true, groupRadius: 6
        }), ["systemMonitor", "currentApp", "media", "bluetooth", "tray"], compactOptions),
        "work": profile({}, []),
        "media": profile({
            barHeight: 34, transparentBarTopMargin: 7, barTransparent: true,
            barTransparentBorder: true
        }, ["bluetooth", "tray"]),
        "presentation": profile(Object.assign({}, compact, {
            pillsTransparent: true, transparentBarTopMargin: 8, barTransparent: true,
            barTransparentBorder: true, groupRadius: 6
        }), ["arch", "systemMonitor", "currentApp", "workspaces", "media", "audio",
            "bluetooth", "tray"], compactOptions)
    };
}

function cloneValue(value) {
    return value === undefined ? undefined : JSON.parse(JSON.stringify(value));
}

function sameValue(left, right) {
    return JSON.stringify(left) === JSON.stringify(right);
}

// `profile` with every profile setting, as a fresh object: missing settings
// take their default and the bar elements are normalized. Other keys are
// dropped.
function completeProfile(profile) {
    const source = profile || {};
    const complete = {};

    for (const key of profileKeys)
        complete[key] = cloneValue(source[key] !== undefined ? source[key] : defaultProfile[key]);
    complete.barElements = normalizeBarElements(complete.barElements);
    return complete;
}

// The profile edited first and given to new monitors: the default one if it
// exists, else the first by name ("" without profiles).
function defaultProfileName(barProfiles) {
    if (barProfiles && barProfiles[defaultBarProfile])
        return defaultBarProfile;

    const names = Object.keys(barProfiles || {}).sort();
    return names.length > 0 ? names[0] : "";
}

// How a bar profile is shown: its name with a capital first letter.
function profileDisplayName(profileName) {
    return profileName.length > 0 ? profileName.charAt(0).toUpperCase() + profileName.slice(1) : "";
}

// Every bar profile as an option to choose, { label, value }, in name order.
function profileChoices(barProfiles) {
    return Object.keys(barProfiles || {}).sort()
        .map(name => ({ label: profileDisplayName(name), value: name }));
}

// The saved values of `profileName`, completed.
function savedProfile(state, profileName) {
    return completeProfile(state.barProfiles && state.barProfiles[profileName]);
}

// The edited profile as monitors drawing it show it: with its pending changes.
function editedProfile(state) {
    return state.pendingProfile
        ? completeProfile(state.pendingProfile)
        : savedProfile(state, state.editingBarProfile);
}

// True when the edited profile has pending changes.
function isModified(state) {
    return !!state.pendingProfile
        && !sameValue(completeProfile(state.pendingProfile),
            savedProfile(state, state.editingBarProfile));
}

// Changes that set `values` (profile settings) on the edited profile as
// pending changes. Back at the saved values, nothing is pending.
function setValues(state, values) {
    const pending = editedProfile(state);

    for (const key in values) {
        if (profileKeys.indexOf(key) !== -1)
            pending[key] = cloneValue(values[key]);
    }

    const pendingState = Object.assign({}, state, { pendingProfile: pending });
    return { pendingProfile: isModified(pendingState) ? pending : null };
}

// Changes that make `profileName` the edited profile. Rejected (null) when the
// profile does not exist or the edited one has pending changes: they must be
// saved or discarded first.
function editProfile(state, profileName) {
    if (!state.barProfiles[profileName] || isModified(state))
        return null;

    return { editingBarProfile: profileName, pendingProfile: null };
}

// Changes that drop the pending changes.
function discardChanges(state) {
    return { pendingProfile: null };
}

// Changes that store the pending changes in the edited profile.
function saveProfile(state) {
    const profiles = cloneValue(state.barProfiles);
    profiles[state.editingBarProfile] = editedProfile(state);

    return { barProfiles: profiles, pendingProfile: null };
}

// The name offered when duplicating `profileName`: the first free
// "<name> N", counting from 2.
function suggestedDuplicateName(state, profileName) {
    let number = 2;
    while (state.barProfiles[profileName + " " + number] !== undefined)
        number++;
    return profileName + " " + number;
}

// Duplicate and Delete need the saved profiles: unavailable while the edited
// profile has pending changes.
function canDuplicateOrDelete(state) {
    return !isModified(state);
}

// Why `newName` cannot name a new profile: "empty", "exists", or "" if it can.
// Names are trimmed.
function duplicateNameError(state, newName) {
    const name = String(newName || "").trim();

    if (name.length === 0)
        return "empty";
    return state.barProfiles[name] !== undefined ? "exists" : "";
}

// Changes that copy the saved `profileName` as `newName` (trimmed) and edit
// the copy. Rejected (null) with pending changes, an unknown profile or a
// name duplicateNameError refuses.
function duplicateProfile(state, profileName, newName) {
    if (!canDuplicateOrDelete(state) || !state.barProfiles[profileName]
            || duplicateNameError(state, newName) !== "")
        return null;

    newName = String(newName).trim();
    const profiles = cloneValue(state.barProfiles);
    profiles[newName] = cloneValue(profiles[profileName]);

    return { barProfiles: profiles, editingBarProfile: newName, pendingProfile: null };
}

// The monitors that draw `profileName`.
function monitorsUsingProfile(displaySettings, profileName) {
    return Object.keys(displaySettings || {}).filter(monitorName =>
        monitorDisplaySettings(displaySettings, monitorName).barProfile === profileName);
}

// Why `profileName` cannot be deleted: "pending" (pending changes), "missing",
// "last" (the only profile left), "assigned" (a monitor draws it, see
// monitorsUsingProfile), or "" if it can.
function deleteRejection(state, displaySettings, profileName) {
    if (!canDuplicateOrDelete(state))
        return "pending";
    if (!state.barProfiles[profileName])
        return "missing";
    if (Object.keys(state.barProfiles).length <= 1)
        return "last";
    return monitorsUsingProfile(displaySettings, profileName).length > 0 ? "assigned" : "";
}

// Changes that remove `profileName`; null when deleteRejection refuses.
// Deleting the edited profile edits the first remaining one by name, as the
// panel lists them.
function deleteProfile(state, displaySettings, profileName) {
    if (deleteRejection(state, displaySettings, profileName) !== "")
        return null;

    const profiles = cloneValue(state.barProfiles);
    delete profiles[profileName];

    if (profileName !== state.editingBarProfile)
        return { barProfiles: profiles };

    return {
        barProfiles: profiles,
        editingBarProfile: Object.keys(profiles).sort()[0],
        pendingProfile: null
    };
}

// The value of `key` a monitor drawing `profileName` shows: with the pending
// changes while the profile is edited, otherwise its saved value (the
// default for unknown profiles and keys).
function profileValue(state, profileName, key) {
    const profile = profileName === state.editingBarProfile
        ? editedProfile(state) : savedProfile(state, profileName);
    return profile[key];
}

const densityPresets = {
    "compact": {
        barHeight: 30, horizontalPadding: 8, spacing: 4,
        pillVerticalPadding: 2, workspacePadding: 3, textSize: 13
    },
    "balanced": {
        barHeight: 34, horizontalPadding: 12, spacing: 8,
        pillVerticalPadding: 3, workspacePadding: 4, textSize: 14
    },
    "spacious": {
        barHeight: 38, horizontalPadding: 16, spacing: 12,
        pillVerticalPadding: 5, workspacePadding: 5, textSize: 15
    }
};

// Changes that fill in the bar sizes of a density preset (a shortcut: the
// preset itself is not stored); unknown presets use balanced sizes.
function densityPresetChanges(preset) {
    const changes = {};
    const sizes = densityPresets[preset] || densityPresets.balanced;

    for (const key in sizes)
        changes[key] = sizes[key];

    return changes;
}

// The density preset whose sizes `profile` has, or "" when none matches.
function matchingDensityPreset(profile) {
    for (const preset in densityPresets) {
        const sizes = densityPresets[preset];
        let matches = true;
        for (const key in sizes) {
            if (profile[key] !== sizes[key])
                matches = false;
        }
        if (matches)
            return preset;
    }

    return "";
}

// Display settings of a monitor. Every monitor has its own entry with an
// explicit bar profile (see assignNewMonitor); until a new monitor gets one
// its bar profile is "" and its bar shows the default settings.
function monitorDisplaySettings(displaySettings, monitorName) {
    const configured = (displaySettings || {})[monitorName] || {};

    return {
        barVisible: configured.barVisible !== false,
        barProfile: configured.barProfile || ""
    };
}

// New displaySettings in which `monitorName`, a monitor without a bar
// profile, draws the default profile (see defaultProfileName) with its bar
// visible; null when it already has a profile.
function assignNewMonitor(displaySettings, monitorName, barProfiles) {
    const configured = (displaySettings || {})[monitorName] || {};

    if (configured.barProfile)
        return null;

    const updated = Object.assign({}, displaySettings);
    updated[monitorName] = Object.assign({ barVisible: true }, configured,
        { barProfile: defaultProfileName(barProfiles) });
    return updated;
}

// The bar profile a monitor draws.
function profileForMonitor(displaySettings, monitorName) {
    return monitorDisplaySettings(displaySettings, monitorName).barProfile;
}


function findElement(barElements, id) {
    for (const zoneName of zoneNames) {
        const index = (barElements[zoneName] || []).findIndex(element => element.id === id);
        if (index !== -1)
            return { zone: zoneName, index: index };
    }

    return null;
}

// The zone an element is listed in, or "" when it is not listed.
function elementZone(barElements, id) {
    const found = findElement(barElements || {}, id);
    return found ? found.zone : "";
}

function elementEnabled(barElements, id) {
    const found = findElement(barElements || {}, id);
    return found !== null && barElements[found.zone][found.index].enabled !== false;
}

function setElementEnabled(barElements, id, enabled) {
    const updated = cloneValue(barElements);
    const found = findElement(updated, id);

    if (found)
        updated[found.zone][found.index].enabled = enabled;
    return updated;
}

// Moves an element to the end of `zoneName`; its own zone keeps it in place.
function moveElementToZone(barElements, id, zoneName) {
    const updated = cloneValue(barElements);
    const found = findElement(updated, id);

    if (!found || found.zone === zoneName || zoneNames.indexOf(zoneName) === -1)
        return updated;

    const source = updated[found.zone];
    const tokens = groupTokens(source);
    const element = source.splice(found.index, 1)[0];
    tokens.splice(found.index, 1);
    relink(source, tokens);
    delete element.joinPrevious;
    updated[zoneName].push(element);
    return updated;
}

// Moves an element `offset` places within its zone; past the edges, nothing.
function moveElement(barElements, id, offset) {
    const updated = cloneValue(barElements);
    const found = findElement(updated, id);

    if (!found)
        return updated;

    const list = updated[found.zone];
    const target = found.index + offset;
    if (target < 0 || target >= list.length)
        return updated;

    const tokens = groupTokens(list);
    list.splice(target, 0, list.splice(found.index, 1)[0]);
    tokens.splice(target, 0, tokens.splice(found.index, 1)[0]);
    relink(list, tokens);
    return updated;
}

// The group each entry of a zone list belongs to, as a number: an entry that
// joins the previous one shares its number.
function groupTokens(list) {
    let token = -1;
    return list.map((element, index) => index > 0 && element.joinPrevious ? token : ++token);
}

// Sets "join previous" on `list` (in place) from its group numbers, so a move
// keeps groups contiguous: an element that steps out of its group leaves it
// and one that steps into a group does not join it.
function relink(list, tokens) {
    for (let index = 0; index < list.length; index++) {
        if (index > 0 && tokens[index] === tokens[index - 1])
            list[index].joinPrevious = true;
        else
            delete list[index].joinPrevious;
    }
}

// Whether an element can join the previous one: not the first of its zone.
function canJoinPrevious(barElements, id) {
    const found = findElement(barElements || {}, id);
    return found !== null && found.index > 0;
}

function elementJoined(barElements, id) {
    const found = findElement(barElements || {}, id);
    return found !== null && found.index > 0
        && barElements[found.zone][found.index].joinPrevious === true;
}

// Turns "join previous" on or off; no effect on the first element of a zone.
function setElementJoined(barElements, id, joined) {
    const updated = cloneValue(barElements);
    const found = findElement(updated, id);

    if (!found || found.index === 0)
        return updated;

    if (joined)
        updated[found.zone][found.index].joinPrevious = true;
    else
        delete updated[found.zone][found.index].joinPrevious;
    return updated;
}

// The options of element `id`, completed with their defaults ({} for an
// element without options) and kept within their limits, as a fresh object.
function elementOptions(barElements, id) {
    const found = findElement(barElements || {}, id);
    const stored = found ? barElements[found.zone][found.index].options || {} : {};
    const options = cloneValue(elementOptionDefaults[id] || {});

    for (const option in options) {
        if (stored[option] !== undefined)
            options[option] = limitedOption(id, option, cloneValue(stored[option]), options[option]);
    }

    return options;
}

function elementOption(barElements, id, option) {
    return elementOptions(barElements, id)[option];
}

// Sets an option of element `id`; options the element does not have are
// ignored.
function setElementOption(barElements, id, option, value) {
    const updated = cloneValue(barElements);
    const found = findElement(updated, id);

    if (found && elementOptionDefaults[id] && option in elementOptionDefaults[id]) {
        const options = elementOptions(updated, id);
        options[option] = cloneValue(value);
        updated[found.zone][found.index].options = options;
    }
    return updated;
}

// Adds missing element `id` next to its default neighbours: right after the
// element before it in elementIds, else right before the one after it, in
// that element's zone; else at the end of the right zone.
function insertMissingElement(normalized, id) {
    const entry = { id: id, enabled: disabledElementIds.indexOf(id) === -1 };
    const index = elementIds.indexOf(id);
    const before = findElement(normalized, elementIds[index - 1]);
    const after = findElement(normalized, elementIds[index + 1]);

    if (before)
        normalized[before.zone].splice(before.index + 1, 0, entry);
    else if (after)
        normalized[after.zone].splice(after.index, 0, entry);
    else
        normalized.right.push(entry);
}

// Every known element listed exactly once: unknown and repeated entries are
// dropped (the first one wins) and missing elements are added next to their
// default neighbours (see insertMissingElement), enabled unless listed in
// disabledElementIds. Elements with options get all of them.
function normalizeBarElements(barElements) {
    const normalized = { left: [], center: [], right: [] };
    const seen = [];

    for (const zoneName of zoneNames) {
        for (const element of (barElements || {})[zoneName] || []) {
            if (elementIds.indexOf(element.id) === -1 || seen.indexOf(element.id) !== -1)
                continue;
            seen.push(element.id);
            const copy = cloneValue(element);
            if (normalized[zoneName].length === 0 || !copy.joinPrevious)
                delete copy.joinPrevious;
            delete copy.options;
            normalized[zoneName].push(copy);
        }
    }

    for (const id of elementIds) {
        if (seen.indexOf(id) === -1)
            insertMissingElement(normalized, id);
    }

    for (const zoneName of zoneNames) {
        for (const element of normalized[zoneName]) {
            if (elementOptionDefaults[element.id])
                element.options = elementOptions(barElements, element.id);
        }
    }

    return normalized;
}

// Groups: an element with `joinPrevious` shares one background with the
// enabled element before it in its zone. Disabled elements belong to no group
// and the first enabled element of a zone joins nothing. `isShown` narrows
// the elements further (the bar passes what it actually draws).
function zoneGroups(barElements, zoneName, isShown) {
    const result = [];

    for (const element of (barElements || {})[zoneName] || []) {
        if (element.enabled === false || (isShown && !isShown(element.id)))
            continue;
        if (element.joinPrevious && result.length > 0)
            result[result.length - 1].push(element.id);
        else
            result.push([element.id]);
    }

    return result;
}
