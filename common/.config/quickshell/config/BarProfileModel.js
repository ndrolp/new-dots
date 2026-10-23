.pragma library

// Bar profile model: pure logic over plain appearance state, no Quickshell.
// Functions take state and return the changes to persist; they never mutate.

const profileKeys = [
    "densityPreset", "barHeight", "horizontalPadding", "spacing", "radius",
    "workspaceButtonSize", "textSize", "archButtonHorizontalPadding",
    "activeWorkspaceHorizontalPadding", "pillVerticalPadding", "workspacePadding",
    "structuralVerticalPadding",
    "workspaceGlyphsEnabled", "hideEmptyWorkspaces", "workspaceAppCountVisible",
    "workspaceGlyphs", "pillsTransparent", "transparentBarTopMargin",
    "transparentBarSlanted", "statusIsland", "statusIslandRadius", "barTransparent",
    "barTransparentBorder", "barOpacity", "barElements",
    "notificationBadgeVisible", "mediaTitleVisible", "audioMeterVisible",
    "batteryPercentageVisible",
    "statusModuleGroups", "backgroundClockEnabled",
    "backgroundClockCalendarEnabled", "backgroundClockPosition",
    "backgroundClockSize", "backgroundClockOpacity", "backgroundClockDateFormat",
    "desktopMediaEnabled", "desktopMediaPosition", "desktopSystemEnabled",
    "desktopSystemPosition", "desktopCalendarEnabled", "desktopCalendarPosition",
    "desktopNetworkEnabled", "desktopNetworkPosition", "desktopWeatherEnabled",
    "desktopWeatherPosition", "desktopWeatherLocation", "desktopWidgetOrder",
    "notificationPopupLocation"
];

function cloneValue(value) {
    return value === undefined ? undefined : JSON.parse(JSON.stringify(value));
}

// Changes that make `profileName` the active profile, copying its saved values
// over the live settings. Returns null when the profile does not exist.
function applyProfile(state, profileName) {
    const profile = state.barProfiles[profileName];

    if (!profile)
        return null;

    const changes = {};

    for (let index = 0; index < profileKeys.length; index++) {
        const key = profileKeys[index];
        if (profile[key] !== undefined)
            changes[key] = cloneValue(profile[key]);
    }

    changes.activeBarProfile = profileName;
    return changes;
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

// Changes that store the live settings as `profileName` and make it active.
function saveProfile(state, profileName) {
    const profiles = cloneValue(state.barProfiles);
    profiles[profileName] = currentLayout(state);

    return {
        barProfiles: profiles,
        activeBarProfile: profileName
    };
}

// The value of `key` for `profileName`: live while the profile is active,
// otherwise its saved value, falling back to the live one if it has none.
function profileValue(state, profileName, key) {
    if (profileName === state.activeBarProfile)
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

// Changes that apply a density preset; unknown presets use balanced sizes.
function densityPresetChanges(preset) {
    const changes = { densityPreset: preset };
    const sizes = densityPresets[preset] || densityPresets.balanced;

    for (const key in sizes)
        changes[key] = sizes[key];

    return changes;
}

// Display settings of a monitor, completed from the "default" entry.
function monitorDisplaySettings(displaySettings, monitorName) {
    const configured = displaySettings[monitorName];
    const defaults = displaySettings["default"] || {};

    return {
        barVisible: configured && configured.barVisible !== undefined
            ? configured.barVisible : defaults.barVisible !== false,
        backgroundClockVisible: configured && configured.backgroundClockVisible !== undefined
            ? configured.backgroundClockVisible : defaults.backgroundClockVisible !== false,
        barProfile: configured && configured.barProfile !== undefined
            ? configured.barProfile : defaults.barProfile || ""
    };
}

// The bar profile a monitor draws, or `fallbackProfile` when it has none.
function profileForMonitor(displaySettings, monitorName, fallbackProfile) {
    return monitorDisplaySettings(displaySettings, monitorName).barProfile || fallbackProfile;
}

// Bar elements: every piece of the bar, one type. A profile stores them as
// `barElements`: { left: [...], center: [...], right: [...] }, each entry
// { id, enabled }. Order within a zone is the order of the list.
const zoneNames = ["left", "center", "right"];

const elementIds = [
    "arch", "systemMonitor", "currentApp", "workspaces",
    "notifications", "recording", "media", "audio", "bluetooth", "tray",
    "network", "battery", "clock"
];

// Legacy layout: fixed order of the former "structural" elements and the
// default order of the former status modules.
const legacyStructuralOrder = ["arch", "system", "currentApp", "workspaces"];
const legacyStructuralPlacement = {
    "arch": "left", "system": "left", "currentApp": "left", "workspaces": "center"
};
const legacyModuleOrder = [
    "notifications", "recording", "media", "audio", "bluetooth", "tray", "network",
    "battery", "clock"
];
const legacyElementKeys = [
    "statusModuleOrder", "statusModuleEnabled", "statusModulePlacement",
    "barElementEnabled", "barElementPlacement"
];

function legacyModuleSequence(savedOrder) {
    const order = [];

    for (const module of savedOrder || []) {
        if (legacyModuleOrder.indexOf(module) !== -1 && order.indexOf(module) === -1)
            order.push(module);
    }

    for (const module of legacyModuleOrder) {
        if (order.indexOf(module) === -1)
            order.push(module);
    }

    return order;
}

// Bar elements equivalent to a legacy layout: in each zone the structural
// elements come first in their fixed order, then the status modules in
// their saved order, as the bar used to draw them.
function migrateBarElements(layout) {
    const barElements = { left: [], center: [], right: [] };
    const structuralEnabled = layout.barElementEnabled || {};
    const structuralPlacement = layout.barElementPlacement || {};
    const moduleEnabled = layout.statusModuleEnabled || {};
    const modulePlacement = layout.statusModulePlacement || {};

    for (const element of legacyStructuralOrder) {
        const zoneName = structuralPlacement[element] || legacyStructuralPlacement[element];
        barElements[zoneName].push({
            id: element === "system" ? "systemMonitor" : element,
            enabled: structuralEnabled[element] !== false
        });
    }

    for (const module of legacyModuleSequence(layout.statusModuleOrder)) {
        barElements[modulePlacement[module] || "right"].push({
            id: module,
            enabled: moduleEnabled[module] !== false
        });
    }

    return barElements;
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

    const element = updated[found.zone].splice(found.index, 1)[0];
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

    const element = list.splice(found.index, 1)[0];
    list.splice(target, 0, element);
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
            normalized[zoneName].push(cloneValue(element));
        }
    }

    for (const id of elementIds) {
        if (seen.indexOf(id) === -1)
            normalized.right.push({ id: id, enabled: true });
    }

    return normalized;
}

function migrateLayoutElements(layout) {
    if (layout.barElements !== undefined)
        return layout;

    const migrated = cloneValue(layout);
    migrated.barElements = migrateBarElements(layout);
    for (const key of legacyElementKeys)
        delete migrated[key];
    return migrated;
}

// Migration step: the live bar and every saved profile replace the legacy
// structural/status-module keys with `barElements`. Self-contained so it can
// be chained with other migration steps; already migrated layouts are kept.
function migrateElementOrder(state) {
    const migrated = migrateLayoutElements(state);
    const profiles = {};

    for (const profileName in state.barProfiles || {})
        profiles[profileName] = migrateLayoutElements(state.barProfiles[profileName]);

    if (state.barProfiles !== undefined)
        migrated.barProfiles = profiles;
    return migrated;
}
