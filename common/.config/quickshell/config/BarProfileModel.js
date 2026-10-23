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
    "barTransparentBorder", "barOpacity", "statusModuleOrder", "statusModuleEnabled",
    "notificationBadgeVisible", "mediaTitleVisible", "audioMeterVisible",
    "batteryPercentageVisible",
    "statusModuleGroups", "statusModulePlacement", "barElementEnabled",
    "barElementPlacement", "backgroundClockEnabled",
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
