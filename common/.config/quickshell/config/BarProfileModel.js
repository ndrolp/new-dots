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
    "arch", "systemMonitor", "currentApp", "appMenu", "workspaces",
    "notifications", "recording", "privacy", "keepAwake", "media", "cava", "audio", "bluetooth", "tray",
    "network", "battery", "clock", "pomodoro"
];
const defaultElementZones = {
    "arch": "left", "systemMonitor": "left", "currentApp": "left", "appMenu": "left",
    "workspaces": "center"
};
// Elements that start disabled: in every default profile and wherever a
// profile does not list them yet.
const disabledElementIds = ["cava", "appMenu"];

// The elements with both an icon and text (a value, a title, a time), which
// can show either or both: on the bar, and separately in a capsule at rest
// (collapsed), where room is short. An element never shows neither: with both
// off it keeps its icon (iconTextShown).
const iconTextElementIds = ["systemMonitor", "currentApp", "recording", "media", "audio",
    "battery", "clock"];
const iconTextOptionDefaults = Object.freeze({
    iconVisible: true, textVisible: true, restIconVisible: true, restTextVisible: true
});

// The options of the elements that have any, with their defaults.
const elementOptionDefaults = {
    "workspaces": {
        glyphsEnabled: false,
        glyphs: ["", "", "", "", "", "", "", "", "", "",
            "", "", "", "", "", "", "", "", "", ""],
        hideEmpty: false,
        appCountVisible: true,
        radius: 8,
        // The room above and below the buttons, across the bar: to the bar's
        // edges on an opaque bar, to the edge of their own pill on a
        // transparent one.
        verticalPadding: 5
    },
    "notifications": { badgeVisible: true },
    // `color` names one of the theme's colors, so it follows the theme.
    "cava": { barCount: 12, barWidth: 3, color: "blue" },
    "audio": { meterVisible: true }
};
for (const id of iconTextElementIds)
    elementOptionDefaults[id] = Object.assign({}, elementOptionDefaults[id] || {}, iconTextOptionDefaults);

// Whether element `id` shows its icon and its text, { icon, text }: by its
// bar options, or its at-rest ones while `resting` (a collapsed capsule).
// With both off it keeps its icon, so it never disappears. An element without
// these options shows both.
function iconTextShown(barElements, id, resting) {
    if (iconTextElementIds.indexOf(id) === -1)
        return { icon: true, text: true };

    const options = elementOptions(barElements, id);
    const icon = resting ? options.restIconVisible : options.iconVisible;
    const text = resting ? options.restTextVisible : options.textVisible;
    return { icon: icon || !text, text: text };
}

// The bar elements that can be live elements (see GLOSSARY.md): a capsule can
// show them beside its workspace pills, collapsed only while they are active.
// Keep-awake is live only if a profile places it so: by default it is hidden.
// Each one says when it is active in LiveElements.activeRules.
const liveElementIds = ["recording", "media", "keepAwake", "pomodoro", "privacy"];

// Whether bar element `id` can be a live element, so a capsule profile can
// place it live left or right of the workspace pills.
function canBeLive(id) {
    return liveElementIds.indexOf(id) !== -1;
}

// Where a collapsed capsule puts a bar element, its collapsed place: hidden,
// shown in its row, or live beside its workspace pills, on the left or the
// right. Only the elements that can be live take the live places, and the
// workspaces, which the capsule shows as pills, take none.
const capsulePlaceNames = ["hidden", "shown", "liveLeft", "liveRight"];
const livePlaceSides = { liveLeft: "left", liveRight: "right" };
const capsulePlaceLabels = {
    hidden: "Hidden", shown: "Shown", liveLeft: "Live left", liveRight: "Live right"
};

// The collapsed places element `id` can take, in the order they are offered.
function capsulePlacesFor(id) {
    if (id === "workspaces" || elementIds.indexOf(id) === -1)
        return [];
    return canBeLive(id) ? capsulePlaceNames : capsulePlaceNames.slice(0, 2);
}

// The side of the workspace pills `place` sits on, or "" for a place that
// isn't live.
function liveSide(place) {
    return livePlaceSides[place] || "";
}

// The collapsed places a profile starts with: media live left, the
// recording indicator, the privacy indicator and the pomodoro live right
// (from the pills outward, in the order elementIds lists them), `shown` in
// the row (by default Arch, the clock and the control center), every other
// element hidden.
function capsulePlacesShowing(shown) {
    const livePlaces = { media: "liveLeft", recording: "liveRight", privacy: "liveRight",
        pomodoro: "liveRight" };
    const places = {};

    for (const id of elementIds) {
        if (capsulePlacesFor(id).length === 0)
            continue;
        places[id] = livePlaces[id] || (shown.indexOf(id) !== -1 ? "shown" : "hidden");
    }
    return places;
}

const defaultCapsulePlaces = Object.freeze(capsulePlacesShowing(["arch", "clock",
    "notifications"]));

// `places` with a collapsed place for every element that takes one, as a
// fresh object: missing or unknown places, or ones the element can't take,
// fall back to the default one; unknown elements are dropped.
function completeCapsulePlaces(places) {
    const source = places && typeof places === "object" ? places : {};
    const complete = {};

    for (const id in defaultCapsulePlaces)
        complete[id] = capsulePlacesFor(id).indexOf(source[id]) !== -1 ? source[id] : defaultCapsulePlaces[id];
    return complete;
}

// The ids of the bar elements `barElements` lists in each collapsed place
// of `places` (completed, see completeCapsulePlaces), in the profile's order,
// enabled or not: { hidden, shown, live: { left, right } }. The workspaces,
// which take no place, are in none.
function capsulePlaceIds(barElements, places) {
    const complete = completeCapsulePlaces(places);
    const ids = { hidden: [], shown: [], live: { left: [], right: [] } };

    for (const zoneName of zoneNames)
        ((barElements || {})[zoneName] || []).forEach(element => {
            const place = complete[element.id];
            if (liveSide(place) !== "")
                ids.live[liveSide(place)].push(element.id);
            else if (place !== undefined)
                ids[place].push(element.id);
        });
    return ids;
}

// What a capsule's every place for `id` is offered as: [{ label, value }],
// none for an element without places.
function capsulePlaceChoices(id) {
    return capsulePlacesFor(id).map(place => ({ label: capsulePlaceLabels[place], value: place }));
}

// `places` with element `id` at `place`, as a new completed object; a place
// the element can't take changes nothing.
function setCapsulePlace(places, id, place) {
    const updated = completeCapsulePlaces(places);

    if (capsulePlacesFor(id).indexOf(place) !== -1)
        updated[id] = place;
    return updated;
}

// What the options that can't take any value accept: a number in a range
// ({ kind: "number", from, to }) or one of some values ({ kind: "choice",
// choices }). A value outside them is clamped, or falls back. Every other
// option is a switch.
const elementOptionLimits = {
    "workspaces": {
        radius: { kind: "number", from: 0, to: 24 },
        verticalPadding: { kind: "number", from: 0, to: 16 }
    },
    "cava": {
        barCount: { kind: "number", from: 6, to: 32 },
        barWidth: { kind: "number", from: 1, to: 8 },
        color: { kind: "choice", choices: ["accent", "blue", "green", "yellow", "orange", "red", "purple", "text"] }
    }
};

// How the Bar section edits option `option` of element `id`: { kind:
// "switch" }, { kind: "number", from, to } or { kind: "choice", choices:
// [{ label, value }] }, each value labelled with a capital first letter.
function elementOptionField(id, option) {
    const limit = (elementOptionLimits[id] || {})[option];

    if (!limit)
        return { kind: "switch" };
    if (limit.kind === "choice") {
        return { kind: "choice", choices: limit.choices.map(value => ({
            label: value.charAt(0).toUpperCase() + value.slice(1), value: value })) };
    }
    return { kind: "number", from: limit.from, to: limit.to };
}

function limitedOption(id, option, value, fallback) {
    const limit = (elementOptionLimits[id] || {})[option];

    if (!limit)
        return value;
    if (limit.kind === "choice")
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

// The screen edges a bar can sit on, its Bar position.
const barPositions = ["top", "bottom", "left", "right"];

// How a bar looks, its bar style: opaque (a solid bar along the edge),
// transparent (floating elements away from the edge), docked (zones hanging
// from the edge, outlined like an attached popup) or capsule (a single centred
// capsule floating away from the edge).
const barStyles = ["opaque", "transparent", "docked", "capsule"];

// Whether a bar profile, or anything with its { barStyle }, is of each bar
// style. Every bar style but opaque is see-through.
function opaque(bar) {
    return bar.barStyle === "opaque";
}

function transparent(bar) {
    return bar.barStyle === "transparent";
}

function docked(bar) {
    return bar.barStyle === "docked";
}

// Whether the bar is a capsule at rest (collapsed), where the elements show
// their at-rest icon and text (iconTextShown). Takes { barStyle,
// capsuleExpanded }.
function resting(bar) {
    return capsule(bar) && !bar.capsuleExpanded;
}

function capsule(bar) {
    return bar.barStyle === "capsule";
}

// The Bar positions a bar of this bar style can take: a capsule only sits at
// the top or the bottom.
function barPositionsFor(barStyle) {
    return barStyle === "capsule" ? ["top", "bottom"] : barPositions;
}

// Every setting a bar profile stores, with the value a profile that lacks it
// gets.
const defaultProfile = {
    barPosition: "top",
    barStyle: "opaque",
    barHeight: 32,
    horizontalPadding: 12,
    spacing: 8,
    radius: 8,
    workspaceButtonSize: 20,
    textSize: 14,
    // How big the bar elements' icons are, apart from their text.
    iconSize: 14,
    archButtonHorizontalPadding: 6,
    activeWorkspaceHorizontalPadding: 6,
    pillVerticalPadding: 3,
    workspacePadding: 4,
    elementVerticalPadding: 5,
    pillsTransparent: false,
    transparentBarTopMargin: 0,
    // The room inside a capsule across the bar, on both sides of its
    // contents (BarPlacement.capsulePadding).
    capsuleVerticalPadding: 0,
    groupRadius: 8,
    // The room inside a group's background: between its edges and its first
    // and last element along the bar, and from the bar's edges across it.
    groupHorizontalPadding: 8,
    groupVerticalPadding: 0,
    barBorder: false,
    elementBorder: false,
    groupBorder: false,
    barOpacity: 100,
    // On a capsule, whether new notifications show inside the focused
    // monitor's capsule instead of as toasts (CapsuleRouting.notificationTarget).
    capsuleNotifications: false,
    barElements: defaultBarElements([]),
    // Each bar element's collapsed place, by id (see capsulePlacesFor), when
    // the profile enables it; they show in the profile's order.
    capsulePlaces: defaultCapsulePlaces
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
        barHeight: 30, horizontalPadding: 10, spacing: 4, groupHorizontalPadding: 4, radius: 6,
        workspaceButtonSize: 18, textSize: 13, iconSize: 13, archButtonHorizontalPadding: 5,
        activeWorkspaceHorizontalPadding: 5, pillVerticalPadding: 2, workspacePadding: 3
    };
    const compactOptions = { "workspaces": { hideEmpty: true, appCountVisible: false, radius: 6,
        verticalPadding: 4 } };

    return {
        "minimal": profile(Object.assign({}, compact, {
            pillsTransparent: true, transparentBarTopMargin: 6, barStyle: "transparent",
            barBorder: true, elementBorder: true, groupBorder: true, groupRadius: 6
        }), ["systemMonitor", "currentApp", "media", "bluetooth", "tray"], compactOptions),
        "work": profile({}, []),
        "media": profile({
            barHeight: 34, transparentBarTopMargin: 7, barStyle: "transparent",
            barBorder: true, elementBorder: true, groupBorder: true
        }, ["bluetooth", "tray"]),
        "presentation": profile(Object.assign({}, compact, {
            pillsTransparent: true, transparentBarTopMargin: 8, barStyle: "transparent",
            barBorder: true, elementBorder: true, groupBorder: true, groupRadius: 6
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
// take their default, an unknown bar style too, a Bar position the bar style
// can't take becomes the default one (a capsule on a side moves to the top),
// the bar elements are normalized and so are the collapsed places (see
// completeCapsulePlaces). Other keys are dropped.
function completeProfile(profile) {
    const source = profile || {};
    const complete = {};

    for (const key of profileKeys)
        complete[key] = cloneValue(source[key] !== undefined ? source[key] : defaultProfile[key]);
    if (barStyles.indexOf(complete.barStyle) === -1)
        complete.barStyle = defaultProfile.barStyle;
    if (barPositionsFor(complete.barStyle).indexOf(complete.barPosition) === -1)
        complete.barPosition = defaultProfile.barPosition;
    complete.barElements = normalizeBarElements(complete.barElements);
    complete.capsulePlaces = completeCapsulePlaces(complete.capsulePlaces);
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

// The name of the profile at `position`, counted from 1 in name order (the
// order profileChoices offers), or "" if there is none there.
function profileAt(barProfiles, position) {
    const choice = profileChoices(barProfiles)[position - 1];
    return choice ? choice.value : "";
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

// Why `newName` cannot be `profileName`'s new name: "empty", "same" (its
// current name), "exists" (another profile has it), or "" if it can. Names are
// trimmed.
function renameNameError(state, profileName, newName) {
    const name = String(newName || "").trim();

    if (name.length === 0)
        return "empty";
    if (name === profileName)
        return "same";
    return state.barProfiles[name] !== undefined ? "exists" : "";
}

// Changes that move the saved `profileName` to `newName` (trimmed), keeping
// it edited if it was. Rejected (null) with pending changes, an unknown
// profile or a name renameNameError refuses. The monitors drawing it name it
// in monitors.json, which the caller updates (monitorsUsingProfile).
function renameProfile(state, profileName, newName) {
    if (!canDuplicateOrDelete(state) || !state.barProfiles[profileName]
            || renameNameError(state, profileName, newName) !== "")
        return null;

    newName = String(newName).trim();
    const profiles = cloneValue(state.barProfiles);
    profiles[newName] = profiles[profileName];
    delete profiles[profileName];

    const changes = { barProfiles: profiles, pendingProfile: null };
    if (state.editingBarProfile === profileName)
        changes.editingBarProfile = newName;
    return changes;
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
        pillVerticalPadding: 2, workspacePadding: 3, textSize: 13, iconSize: 13
    },
    "balanced": {
        barHeight: 34, horizontalPadding: 12, spacing: 8,
        pillVerticalPadding: 3, workspacePadding: 4, textSize: 14, iconSize: 14
    },
    "spacious": {
        barHeight: 38, horizontalPadding: 16, spacing: 12,
        pillVerticalPadding: 5, workspacePadding: 5, textSize: 15, iconSize: 15
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

// Sets an option of element `id`, kept within its limits: a number is
// clamped and a choice it does not list keeps the current one. Options the
// element does not have are ignored.
function setElementOption(barElements, id, option, value) {
    const updated = cloneValue(barElements);
    const found = findElement(updated, id);

    if (found && elementOptionDefaults[id] && option in elementOptionDefaults[id]) {
        const options = elementOptions(updated, id);
        options[option] = limitedOption(id, option, cloneValue(value), options[option]);
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
