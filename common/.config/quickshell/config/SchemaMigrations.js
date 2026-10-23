.pragma library
.import "BarProfileModel.js" as BarProfileModel
.import "DesktopWidgetsModel.js" as DesktopWidgetsModel

// Schema migrations of appearance.json and monitors.json: pure functions over
// the stored state, no Quickshell.

const cloneValue = BarProfileModel.cloneValue;
const zoneNames = BarProfileModel.zoneNames;
const defaultBarProfile = BarProfileModel.defaultBarProfile;
const completeDesktopWidgets = DesktopWidgetsModel.completeDesktopWidgets;

// Legacy bar profiles: fixed order of the former "structural" elements and the
// default order of the former status modules.
const legacyStructuralOrder = ["arch", "system", "currentApp", "workspaces"];
const legacyStructuralPlacement = {
    "arch": "left", "system": "left", "currentApp": "left", "workspaces": "center"
};
const legacyStatusElementOrder = [
    "notifications", "recording", "media", "audio", "bluetooth", "tray", "network",
    "battery", "clock"
];
const legacyElementKeys = [
    "statusModuleOrder", "statusModuleEnabled", "statusModulePlacement",
    "barElementEnabled", "barElementPlacement"
];

function legacyStatusElementSequence(savedOrder) {
    const order = [];

    for (const element of savedOrder || []) {
        if (legacyStatusElementOrder.indexOf(element) !== -1 && order.indexOf(element) === -1)
            order.push(element);
    }

    for (const element of legacyStatusElementOrder) {
        if (order.indexOf(element) === -1)
            order.push(element);
    }

    return order;
}

// Bar elements equivalent to a legacy bar profile: in each zone the structural
// elements come first in their fixed order, then the status modules in
// their saved order, as the bar used to draw them.
function migrateBarElements(profile) {
    const barElements = { left: [], center: [], right: [] };
    const structuralEnabled = profile.barElementEnabled || {};
    const structuralPlacement = profile.barElementPlacement || {};
    const statusEnabled = profile.statusModuleEnabled || {};
    const statusPlacement = profile.statusModulePlacement || {};

    for (const element of legacyStructuralOrder) {
        const zoneName = structuralPlacement[element] || legacyStructuralPlacement[element];
        barElements[zoneName].push({
            id: element === "system" ? "systemMonitor" : element,
            enabled: structuralEnabled[element] !== false
        });
    }

    for (const element of legacyStatusElementSequence(profile.statusModuleOrder)) {
        barElements[statusPlacement[element] || "right"].push({
            id: element,
            enabled: statusEnabled[element] !== false
        });
    }

    return barElements;
}

function migrateProfileElements(profile) {
    if (profile.barElements !== undefined)
        return profile;

    const migrated = cloneValue(profile);
    migrated.barElements = migrateBarElements(profile);
    for (const key of legacyElementKeys)
        delete migrated[key];
    return migrated;
}

// Migration step: the live bar and every saved profile replace the legacy
// structural/status-module keys with `barElements`. Self-contained so it can
// be chained with other migration steps; already migrated profiles are kept.
function migrateElementOrder(state) {
    const migrated = migrateProfileElements(state);
    const profiles = {};

    for (const profileName in state.barProfiles || {})
        profiles[profileName] = migrateProfileElements(state.barProfiles[profileName]);

    if (state.barProfiles !== undefined)
        migrated.barProfiles = profiles;
    return migrated;
}

const legacyGroupKeys = ["statusIsland", "statusIslandRadius", "statusModuleGroups"];

function hasLegacyGroups(profile) {
    return legacyGroupKeys.some(key => profile[key] !== undefined);
}

// A former status island packed every zone, left to right, into one centered
// surface: the same as a center zone holding all elements in one group.
function centerGroupElements(barElements) {
    const center = [].concat(barElements.left, barElements.center, barElements.right);

    return {
        left: [],
        center: center.map((element, index) => index > 0
            ? Object.assign({}, element, { joinPrevious: true }) : element),
        right: []
    };
}

// Numbered groups: an element joins the previous enabled element of its zone
// when both had the same group number.
function numberedGroupElements(barElements, numberedGroups) {
    const updated = {};

    for (const zoneName of zoneNames) {
        let previousGroup = 0;
        updated[zoneName] = (barElements[zoneName] || []).map(element => {
            const copy = Object.assign({}, element);
            const group = numberedGroups[element.id] || 0;

            delete copy.joinPrevious;
            if (element.enabled === false)
                return copy;
            if (group !== 0 && group === previousGroup)
                copy.joinPrevious = true;
            previousGroup = group;
            return copy;
        });
    }

    return updated;
}

function migrateProfileGroups(profile) {
    if (!hasLegacyGroups(profile) || profile.barElements === undefined)
        return cloneValue(profile);

    const migrated = cloneValue(profile);
    migrated.barElements = numberedGroupElements(migrated.barElements,
        profile.statusModuleGroups || {});

    if (profile.statusIsland) {
        migrated.barElements = centerGroupElements(migrated.barElements);
        migrated.groupRadius = profile.statusIslandRadius !== undefined
            ? profile.statusIslandRadius : 12;
        migrated.barTransparent = true;
        migrated.transparentBarSlanted = false;
    } else if (profile.radius !== undefined) {
        // Numbered groups were drawn with the corner radius.
        migrated.groupRadius = profile.radius;
    }

    for (const key of legacyGroupKeys)
        delete migrated[key];
    return migrated;
}

// Migration step, chained after migrateElementOrder: numbered groups become
// "join previous" and an active status island becomes a group filling the
// center zone, for the live bar and every saved profile. Already migrated
// profiles are kept.
function migrateGroups(state) {
    const profiles = state.barProfiles;
    const live = Object.assign({}, state);
    delete live.barProfiles;

    const migrated = migrateProfileGroups(live);
    if (profiles !== undefined) {
        migrated.barProfiles = {};
        for (const profileName in profiles)
            migrated.barProfiles[profileName] = migrateProfileGroups(profiles[profileName]);
    }
    return migrated;
}

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

// Step 4: numbered groups and the status island become "join previous" groups.
function migrateBarGroups(appearance, monitors) {
    return { appearance: migrateGroups(appearance), monitors: monitors };
}

// Step 5: density presets are only a shortcut; the stored preset goes away
// from the live settings and every profile.
function dropDensityPreset(appearance, monitors) {
    const migrated = cloneValue(appearance);
    delete migrated.densityPreset;
    for (const profileName in migrated.barProfiles || {})
        delete migrated.barProfiles[profileName].densityPreset;

    return { appearance: migrated, monitors: monitors };
}

// The settings a bar profile stored up to schema version 5; until then the
// top level of appearance.json also held them, as the live settings of the
// edited profile.
const version5ProfileKeys = [
    "barHeight", "horizontalPadding", "spacing", "radius",
    "workspaceButtonSize", "textSize", "archButtonHorizontalPadding",
    "activeWorkspaceHorizontalPadding", "pillVerticalPadding", "workspacePadding",
    "structuralVerticalPadding", "workspaceGlyphsEnabled", "hideEmptyWorkspaces",
    "workspaceAppCountVisible", "workspaceGlyphs", "pillsTransparent",
    "transparentBarTopMargin", "transparentBarSlanted", "groupRadius", "barTransparent",
    "barTransparentBorder", "barOpacity", "barElements", "notificationBadgeVisible",
    "mediaTitleVisible", "audioMeterVisible", "batteryPercentageVisible"
];

// Step 6: pending changes live in memory, so the file keeps only the saved
// profiles and the global settings. The top-level values were what the edited
// (formerly active) profile showed: they win over its saved copy. Other
// profiles keep their saved values and take the top-level ones only for
// settings they did not save, which their monitors drew from the top level.
function foldLiveSettingsIntoProfiles(appearance, monitors) {
    const edited = appearance.editingBarProfile || defaultBarProfile;
    const migrated = cloneValue(appearance);
    const profiles = migrated.barProfiles || {};

    if (!profiles[edited])
        profiles[edited] = {};

    for (const key of version5ProfileKeys) {
        if (appearance[key] === undefined)
            continue;
        for (const profileName in profiles) {
            if (profileName === edited || profiles[profileName][key] === undefined)
                profiles[profileName][key] = cloneValue(appearance[key]);
        }
        delete migrated[key];
    }

    migrated.barProfiles = profiles;
    delete migrated.editingBarProfile;
    return { appearance: migrated, monitors: monitors };
}

const migrationSteps = [
    migrateDesktopWidgetsPerMonitor, migrateBarElementOrder, assignActiveProfileToMonitors,
    migrateBarGroups, dropDensityPreset, foldLiveSettingsIntoProfiles
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
