.pragma library

// Bar profile model: pure logic over plain appearance state, no Quickshell.
// Functions take state and return the changes to persist; they never mutate.

const profileKeys = [
    "barHeight", "horizontalPadding", "spacing", "radius",
    "workspaceButtonSize", "textSize", "archButtonHorizontalPadding",
    "activeWorkspaceHorizontalPadding", "pillVerticalPadding", "workspacePadding",
    "structuralVerticalPadding",
    "workspaceGlyphsEnabled", "hideEmptyWorkspaces", "workspaceAppCountVisible",
    "workspaceGlyphs", "pillsTransparent", "transparentBarTopMargin",
    "transparentBarSlanted", "groupRadius", "barTransparent",
    "barTransparentBorder", "barOpacity", "barElements",
    "notificationBadgeVisible", "mediaTitleVisible", "audioMeterVisible",
    "batteryPercentageVisible"
];

// The bar profile of a monitor nobody has configured yet.
const defaultBarProfile = "minimal";

function cloneValue(value) {
    return value === undefined ? undefined : JSON.parse(JSON.stringify(value));
}

// Profiles are edited through the live settings: they hold the profile being
// edited (`editingBarProfile`) plus its pending changes, and monitors that draw
// it read them directly; every other monitor draws its saved profile. The live
// settings are only a buffer: Quickshell discards them on start (see
// discardChanges), so pending changes never outlive a restart.

function sameValue(left, right) {
    return JSON.stringify(left) === JSON.stringify(right);
}

// True when the live settings differ from the saved edited profile, i.e. the
// profile has pending changes. A key the profile does not save has none.
function isModified(state) {
    const profile = state.barProfiles && state.barProfiles[state.editingBarProfile];

    if (!profile)
        return false;

    for (let index = 0; index < profileKeys.length; index++) {
        const key = profileKeys[index];
        if (profile[key] !== undefined && !sameValue(profile[key], state[key]))
            return true;
    }

    return false;
}

// Changes that load the saved values of `profileName` into the live settings.
// Keys a profile does not save are first stored with the value its monitors
// draw today (the live one), so pending changes never leak into them.
function loadProfile(state, profileName) {
    const profiles = cloneValue(state.barProfiles);
    let completed = false;

    for (const name in profiles) {
        for (let index = 0; index < profileKeys.length; index++) {
            const key = profileKeys[index];
            if (profiles[name][key] === undefined && state[key] !== undefined) {
                profiles[name][key] = cloneValue(state[key]);
                completed = true;
            }
        }
    }

    const changes = completed ? { barProfiles: profiles } : {};
    const profile = profiles[profileName];

    for (let index = 0; index < profileKeys.length; index++) {
        const key = profileKeys[index];
        if (profile[key] !== undefined)
            changes[key] = cloneValue(profile[key]);
    }

    changes.editingBarProfile = profileName;
    return changes;
}

// Changes that make `profileName` the edited profile. Rejected (null) when the
// profile does not exist or the edited one has pending changes: they must be
// saved or discarded first.
function editProfile(state, profileName) {
    if (!state.barProfiles[profileName] || isModified(state))
        return null;

    return loadProfile(state, profileName);
}

// Changes that drop the pending changes: the live settings go back to the
// saved edited profile (or the default one if it no longer exists).
function discardChanges(state) {
    const profileName = state.barProfiles[state.editingBarProfile]
        ? state.editingBarProfile
        : state.barProfiles[defaultBarProfile] ? defaultBarProfile : Object.keys(state.barProfiles)[0];

    return profileName === undefined ? {} : loadProfile(state, profileName);
}

// The live settings that a bar profile stores.
function currentLayout(state) {
    const layout = {};

    for (let index = 0; index < profileKeys.length; index++) {
        const key = profileKeys[index];
        layout[key] = cloneValue(state[key]);
    }

    return layout;
}

// Changes that store the live settings as `profileName` and edit it.
function saveProfile(state, profileName) {
    const profiles = cloneValue(state.barProfiles);
    profiles[profileName] = currentLayout(state);

    return {
        barProfiles: profiles,
        editingBarProfile: profileName
    };
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

    const withCopy = Object.assign({}, state, { barProfiles: profiles });
    return Object.assign({ barProfiles: profiles }, loadProfile(withCopy, newName));
}

// The display settings entries (monitors, and "default" for monitors nobody
// has configured) that draw `profileName`.
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
// Deleting the edited profile edits the default one (or the first left).
function deleteProfile(state, displaySettings, profileName) {
    if (deleteRejection(state, displaySettings, profileName) !== "")
        return null;

    const profiles = cloneValue(state.barProfiles);
    delete profiles[profileName];

    if (profileName !== state.editingBarProfile)
        return { barProfiles: profiles };

    const remaining = Object.assign({}, state, { barProfiles: profiles });
    return Object.assign({ barProfiles: profiles }, discardChanges(remaining));
}

// The value of `key` for `profileName`: live while the profile is edited,
// otherwise its saved value, falling back to the live one if it has none.
function profileValue(state, profileName, key) {
    if (profileName === state.editingBarProfile)
        return state[key];

    const profile = state.barProfiles[profileName];
    return profile && profile[key] !== undefined ? profile[key] : state[key];
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

// The density preset whose sizes the state has, or "" when none matches.
function matchingDensityPreset(state) {
    for (const preset in densityPresets) {
        const sizes = densityPresets[preset];
        let matches = true;
        for (const key in sizes) {
            if (state[key] !== sizes[key])
                matches = false;
        }
        if (matches)
            return preset;
    }

    return "";
}

// Display settings of a monitor, completed from the "default" entry. A monitor
// always has a bar profile: its own, the default entry's, or the default one.
function monitorDisplaySettings(displaySettings, monitorName) {
    const configured = displaySettings[monitorName];
    const defaults = displaySettings["default"] || {};

    return {
        barVisible: configured && configured.barVisible !== undefined
            ? configured.barVisible : defaults.barVisible !== false,
        barProfile: configured && configured.barProfile
            ? configured.barProfile : defaults.barProfile || defaultBarProfile
    };
}

// The bar profile a monitor draws.
function profileForMonitor(displaySettings, monitorName) {
    return monitorDisplaySettings(displaySettings, monitorName).barProfile;
}

// Bar elements: every piece of the bar, one type. A profile stores them as
// `barElements`: { left: [...], center: [...], right: [...] }, each entry
// { id, enabled, joinPrevious? }. Order within a zone is the order of the list.
const zoneNames = ["left", "center", "right"];

const elementIds = [
    "arch", "systemMonitor", "currentApp", "workspaces",
    "notifications", "recording", "media", "audio", "bluetooth", "tray",
    "network", "battery", "clock"
];

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

// Every known element listed exactly once: unknown and repeated entries are
// dropped (the first one wins) and missing elements are added, enabled, at
// the end of the right zone.
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
            normalized[zoneName].push(copy);
        }
    }

    for (const id of elementIds) {
        if (seen.indexOf(id) === -1)
            normalized.right.push({ id: id, enabled: true });
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
