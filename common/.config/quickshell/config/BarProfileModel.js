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
    "statusModuleGroups"
];

// The bar profile of a monitor nobody has configured yet.
const defaultBarProfile = "minimal";

function cloneValue(value) {
    return value === undefined ? undefined : JSON.parse(JSON.stringify(value));
}

// Profiles are edited through the live settings: they hold the profile being
// edited (`editingBarProfile`), and monitors that draw it read them directly.

// Changes that make `profileName` the edited profile: the live settings of the
// previous one are stored first, so no monitor changes, then the saved values
// of `profileName` are loaded. Returns null when the profile does not exist.
function editProfile(state, profileName) {
    const profile = state.barProfiles[profileName];

    if (!profile)
        return null;

    const changes = {};
    if (state.editingBarProfile && state.barProfiles[state.editingBarProfile]) {
        changes.barProfiles = cloneValue(state.barProfiles);
        changes.barProfiles[state.editingBarProfile] = currentLayout(state);
    }

    for (let index = 0; index < profileKeys.length; index++) {
        const key = profileKeys[index];
        if (profile[key] !== undefined)
            changes[key] = cloneValue(profile[key]);
    }

    changes.editingBarProfile = profileName;
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

// Changes that store the live settings as `profileName` and edit it.
function saveProfile(state, profileName) {
    const profiles = cloneValue(state.barProfiles);
    profiles[profileName] = currentLayout(state);

    return {
        barProfiles: profiles,
        editingBarProfile: profileName
    };
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

// Changes that apply a density preset; unknown presets use balanced sizes.
function densityPresetChanges(preset) {
    const changes = { densityPreset: preset };
    const sizes = densityPresets[preset] || densityPresets.balanced;

    for (const key in sizes)
        changes[key] = sizes[key];

    return changes;
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

// ---------------------------------------------------------------------------
// Desktop widgets: configured per monitor in monitors.json under
// displaySettings[monitor].desktopWidgets (the "default" entry is the template
// for monitors without their own entry).

const desktopWidgetNames = ["media", "system", "calendar", "network", "weather"];

const defaultDesktopWidgets = {
    order: ["media", "system", "calendar", "network", "weather"],
    backgroundClock: {
        enabled: true, position: "center", size: 96, opacity: 100,
        dateFormat: "full", calendarEnabled: false
    },
    media: { enabled: false, position: "bottom-left" },
    system: { enabled: false, position: "top-right" },
    calendar: { enabled: false, position: "top-left" },
    network: { enabled: false, position: "bottom-right" },
    weather: { enabled: false, position: "top-center", location: "Ourense, ES" }
};

// `widgets` completed with the built-in defaults, as a fresh object.
function completeDesktopWidgets(widgets) {
    const source = widgets || {};
    const complete = cloneValue(defaultDesktopWidgets);

    for (const key in complete) {
        if (source[key] === undefined)
            continue;
        if (Array.isArray(complete[key]))
            complete[key] = cloneValue(source[key]);
        else
            Object.assign(complete[key], cloneValue(source[key]));
    }

    return complete;
}

// The desktop widgets of a monitor, completed from the "default" entry.
function desktopWidgetsFor(displaySettings, monitorName) {
    const configured = displaySettings[monitorName];
    const defaults = displaySettings["default"];

    if (configured && configured.desktopWidgets)
        return completeDesktopWidgets(configured.desktopWidgets);

    return completeDesktopWidgets(defaults && defaults.desktopWidgets);
}

function withDesktopWidgets(displaySettings, monitorName, widgets) {
    const updated = Object.assign({}, displaySettings);
    const monitorSettings = Object.assign({}, displaySettings[monitorName]);
    monitorSettings.desktopWidgets = widgets;
    updated[monitorName] = monitorSettings;
    return updated;
}

// New displaySettings with `widget.key = value` on `monitorName` only.
function setDesktopWidgetSetting(displaySettings, monitorName, widget, key, value) {
    const widgets = desktopWidgetsFor(displaySettings, monitorName);
    widgets[widget][key] = cloneValue(value);
    return withDesktopWidgets(displaySettings, monitorName, widgets);
}

// The stack order of desktop widgets: known widgets once, missing ones last.
function desktopWidgetOrder(widgets) {
    const savedOrder = (widgets && widgets.order) || [];
    const order = [];

    for (let index = 0; index < savedOrder.length; index++) {
        const widget = savedOrder[index];
        if (desktopWidgetNames.indexOf(widget) !== -1 && order.indexOf(widget) === -1)
            order.push(widget);
    }

    for (let index = 0; index < desktopWidgetNames.length; index++) {
        if (order.indexOf(desktopWidgetNames[index]) === -1)
            order.push(desktopWidgetNames[index]);
    }

    return order;
}

// New displaySettings with `widget` moved by `offset` in the stack order of
// `monitorName`; unchanged when the move would leave the list.
function moveDesktopWidget(displaySettings, monitorName, widget, offset) {
    const widgets = desktopWidgetsFor(displaySettings, monitorName);
    const order = desktopWidgetOrder(widgets);
    const from = order.indexOf(widget);
    const to = from + offset;

    if (from < 0 || to < 0 || to >= order.length)
        return displaySettings;

    order.splice(from, 1);
    order.splice(to, 0, widget);
    widgets.order = order;
    return withDesktopWidgets(displaySettings, monitorName, widgets);
}

// ---------------------------------------------------------------------------
// Schema migration. appearance.json carries `schemaVersion`; each step turns
// version N-1 into N over both files and returns new state (no mutation).

// Old flat appearance keys of the desktop, by desktop widget and option.
const legacyDesktopKeys = {
    backgroundClock: {
        enabled: "backgroundClockEnabled", position: "backgroundClockPosition",
        size: "backgroundClockSize", opacity: "backgroundClockOpacity",
        dateFormat: "backgroundClockDateFormat",
        calendarEnabled: "backgroundClockCalendarEnabled"
    },
    media: { enabled: "desktopMediaEnabled", position: "desktopMediaPosition" },
    system: { enabled: "desktopSystemEnabled", position: "desktopSystemPosition" },
    calendar: { enabled: "desktopCalendarEnabled", position: "desktopCalendarPosition" },
    network: { enabled: "desktopNetworkEnabled", position: "desktopNetworkPosition" },
    weather: {
        enabled: "desktopWeatherEnabled", position: "desktopWeatherPosition",
        location: "desktopWeatherLocation"
    }
};

function isLegacyDesktopKey(key) {
    return key.indexOf("backgroundClock") === 0 || key.indexOf("desktop") === 0;
}

// Desktop widgets read from old flat keys: `primary` first, then `fallback`.
function legacyDesktopWidgets(primary, fallback) {
    function read(key) {
        if (primary && primary[key] !== undefined)
            return primary[key];
        return fallback ? fallback[key] : undefined;
    }

    const widgets = {};
    const order = read("desktopWidgetOrder");
    if (order !== undefined)
        widgets.order = order;

    for (const widget in legacyDesktopKeys) {
        widgets[widget] = {};
        for (const option in legacyDesktopKeys[widget]) {
            const value = read(legacyDesktopKeys[widget][option]);
            if (value !== undefined)
                widgets[widget][option] = value;
        }
    }

    return completeDesktopWidgets(widgets);
}

// Step 1: desktop widgets (incl. background clock) leave the bar profiles and
// move to each monitor; the notification popup location becomes global.
function migrateDesktopWidgetsPerMonitor(appearance, monitors) {
    const active = appearance.activeBarProfile;
    const profiles = appearance.barProfiles || {};
    const displaySettings = cloneValue(monitors.displaySettings) || {};
    const names = Object.keys(displaySettings);
    const assignmentNames = Object.keys(monitors.assignments || {});

    for (let index = 0; index < assignmentNames.length; index++) {
        if (names.indexOf(assignmentNames[index]) === -1)
            names.push(assignmentNames[index]);
    }

    for (let index = 0; index < names.length; index++) {
        const name = names[index];
        const monitorSettings = displaySettings[name] || {};
        const profileName = monitorSettings.barProfile || active;
        const profile = profiles[profileName];
        // The active profile is what was on screen: its live values win.
        const widgets = profileName === active || !profile
            ? legacyDesktopWidgets(appearance, profile)
            : legacyDesktopWidgets(profile, appearance);

        if (monitorSettings.backgroundClockVisible === false)
            widgets.backgroundClock.enabled = false;
        delete monitorSettings.backgroundClockVisible;

        monitorSettings.desktopWidgets = widgets;
        displaySettings[name] = monitorSettings;
    }

    const migratedAppearance = {};
    for (const key in appearance) {
        if (!isLegacyDesktopKey(key))
            migratedAppearance[key] = cloneValue(appearance[key]);
    }

    const migratedProfiles = {};
    for (const profileName in profiles) {
        const profile = {};
        for (const key in profiles[profileName]) {
            if (!isLegacyDesktopKey(key) && key !== "notificationPopupLocation")
                profile[key] = cloneValue(profiles[profileName][key]);
        }
        migratedProfiles[profileName] = profile;
    }
    migratedAppearance.barProfiles = migratedProfiles;

    const migratedMonitors = cloneValue(monitors) || {};
    migratedMonitors.displaySettings = displaySettings;

    return { appearance: migratedAppearance, monitors: migratedMonitors };
}

// Step 2: bar elements replace the legacy structural/status-module keys.
function migrateBarElementOrder(appearance, monitors) {
    return { appearance: migrateElementOrder(appearance), monitors: monitors };
}

// Step 3: no global active profile. Every monitor (and the "default" entry)
// without a bar profile gets the one that was active, explicitly; the active
// profile becomes the profile the panel edits.
function assignActiveProfileToMonitors(appearance, monitors) {
    const active = appearance.activeBarProfile || defaultBarProfile;
    const displaySettings = cloneValue(monitors.displaySettings) || {};
    const names = Object.keys(displaySettings)
        .concat(Object.keys(monitors.assignments || {}), ["default"]);

    for (let index = 0; index < names.length; index++) {
        const monitorSettings = displaySettings[names[index]] || {};
        if (!monitorSettings.barProfile)
            monitorSettings.barProfile = active;
        displaySettings[names[index]] = monitorSettings;
    }

    const migratedAppearance = cloneValue(appearance);
    delete migratedAppearance.activeBarProfile;
    if (!migratedAppearance.editingBarProfile)
        migratedAppearance.editingBarProfile = active;

    const migratedMonitors = cloneValue(monitors) || {};
    migratedMonitors.displaySettings = displaySettings;

    return { appearance: migratedAppearance, monitors: migratedMonitors };
}

const migrationSteps = [
    migrateDesktopWidgetsPerMonitor, migrateBarElementOrder, assignActiveProfileToMonitors
];
const schemaVersion = migrationSteps.length;

function stateVersion(appearance) {
    return appearance && appearance.schemaVersion !== undefined ? appearance.schemaVersion : 0;
}

function needsMigration(appearance) {
    return stateVersion(appearance) < schemaVersion;
}

// Both files brought to the current schema version. Already migrated files
// come back unchanged (as copies).
function migrate(appearance, monitors) {
    let state = { appearance: cloneValue(appearance), monitors: cloneValue(monitors) };

    for (let version = stateVersion(appearance); version < schemaVersion; version++) {
        state = migrationSteps[version](state.appearance, state.monitors);
        state.appearance.schemaVersion = version + 1;
    }

    return state;
}
