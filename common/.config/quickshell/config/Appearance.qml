import QtQuick
import Quickshell.Io

QtObject {
    property alias barHeight: settings.barHeight
    property alias activeBarProfile: settings.activeBarProfile
    property alias barProfiles: settings.barProfiles
    property alias densityPreset: settings.densityPreset
    property alias horizontalPadding: settings.horizontalPadding
    property alias spacing: settings.spacing
    property alias radius: settings.radius
    property alias workspaceButtonSize: settings.workspaceButtonSize
    property alias textSize: settings.textSize
    property alias archButtonHorizontalPadding: settings.archButtonHorizontalPadding
    property alias activeWorkspaceHorizontalPadding: settings.activeWorkspaceHorizontalPadding
    property alias pillVerticalPadding: settings.pillVerticalPadding
    property alias workspacePadding: settings.workspacePadding
    property alias workspaceGlyphsEnabled: settings.workspaceGlyphsEnabled
    property alias hideEmptyWorkspaces: settings.hideEmptyWorkspaces
    property alias workspaceAppCountVisible: settings.workspaceAppCountVisible
    property alias workspaceGlyphs: settings.workspaceGlyphs
    property alias pillsTransparent: settings.pillsTransparent
    property alias transparentBarTopMargin: settings.transparentBarTopMargin
    property alias transparentBarSlanted: settings.transparentBarSlanted
    property alias statusIsland: settings.statusIsland
    property alias statusIslandRadius: settings.statusIslandRadius
    property alias backgroundClockEnabled: settings.backgroundClockEnabled
    property alias backgroundClockCalendarEnabled: settings.backgroundClockCalendarEnabled
    property alias backgroundClockPosition: settings.backgroundClockPosition
    property alias backgroundClockSize: settings.backgroundClockSize
    property alias backgroundClockOpacity: settings.backgroundClockOpacity
    property alias backgroundClockDateFormat: settings.backgroundClockDateFormat
    property alias desktopMediaEnabled: settings.desktopMediaEnabled
    property alias desktopMediaPosition: settings.desktopMediaPosition
    property alias desktopSystemEnabled: settings.desktopSystemEnabled
    property alias desktopSystemPosition: settings.desktopSystemPosition
    property alias desktopCalendarEnabled: settings.desktopCalendarEnabled
    property alias desktopCalendarPosition: settings.desktopCalendarPosition
    property alias desktopNetworkEnabled: settings.desktopNetworkEnabled
    property alias desktopNetworkPosition: settings.desktopNetworkPosition
    property alias desktopWeatherEnabled: settings.desktopWeatherEnabled
    property alias desktopWeatherPosition: settings.desktopWeatherPosition
    property alias desktopWeatherLocation: settings.desktopWeatherLocation
    property alias desktopWidgetOrder: settings.desktopWidgetOrder
    property alias statusModuleOrder: settings.statusModuleOrder
    property alias statusModuleEnabled: settings.statusModuleEnabled
    property alias statusModuleGroups: settings.statusModuleGroups
    property alias statusModulePlacement: settings.statusModulePlacement
    property alias barElementEnabled: settings.barElementEnabled
    property alias barElementPlacement: settings.barElementPlacement
    property alias notificationPopupLocation: settings.notificationPopupLocation
    property alias doNotDisturb: settings.doNotDisturb
    property alias barTransparent: settings.barTransparent
    property alias barTransparentBorder: settings.barTransparentBorder

    readonly property var barProfileKeys: [
        "densityPreset", "barHeight", "horizontalPadding", "spacing", "radius",
        "workspaceButtonSize", "textSize", "archButtonHorizontalPadding",
        "activeWorkspaceHorizontalPadding", "pillVerticalPadding", "workspacePadding",
        "workspaceGlyphsEnabled", "hideEmptyWorkspaces", "workspaceAppCountVisible",
        "workspaceGlyphs", "pillsTransparent", "transparentBarTopMargin",
        "transparentBarSlanted", "statusIsland", "statusIslandRadius", "barTransparent",
        "barTransparentBorder", "statusModuleOrder", "statusModuleEnabled",
        "statusModuleGroups", "statusModulePlacement", "barElementEnabled",
        "barElementPlacement", "backgroundClockEnabled",
        "backgroundClockCalendarEnabled", "backgroundClockPosition",
        "backgroundClockSize", "backgroundClockOpacity", "backgroundClockDateFormat",
        "desktopMediaEnabled", "desktopMediaPosition", "desktopSystemEnabled",
        "desktopSystemPosition", "desktopCalendarEnabled", "desktopCalendarPosition",
        "desktopNetworkEnabled", "desktopNetworkPosition", "desktopWeatherEnabled",
        "desktopWeatherPosition", "desktopWeatherLocation", "desktopWidgetOrder",
        "notificationPopupLocation"
    ]

    function cloneValue(value) {
        return JSON.parse(JSON.stringify(value));
    }

    function currentBarLayout() {
        const layout = {};

        for (let index = 0; index < barProfileKeys.length; index++) {
            const key = barProfileKeys[index];
            layout[key] = cloneValue(settings[key]);
        }

        return layout;
    }

    function applyBarProfile(profileName) {
        const profile = barProfiles[profileName];

        if (!profile)
            return;

        for (let index = 0; index < barProfileKeys.length; index++) {
            const key = barProfileKeys[index];
            if (profile[key] !== undefined)
                settings[key] = cloneValue(profile[key]);
        }

        activeBarProfile = profileName;
    }

    function saveBarProfile(profileName) {
        const profiles = cloneValue(barProfiles);
        profiles[profileName] = currentBarLayout();
        barProfiles = profiles;
        activeBarProfile = profileName;
    }

    function barProfileValue(profileName, key) {
        if (profileName === activeBarProfile)
            return settings[key];

        const profile = barProfiles[profileName];
        return profile && profile[key] !== undefined ? profile[key] : settings[key];
    }

    function applyDensityPreset(preset) {
        densityPreset = preset;

        if (preset === "compact") {
            barHeight = 30;
            horizontalPadding = 8;
            spacing = 4;
            pillVerticalPadding = 2;
            workspacePadding = 3;
            textSize = 13;
        } else if (preset === "spacious") {
            barHeight = 38;
            horizontalPadding = 16;
            spacing = 12;
            pillVerticalPadding = 5;
            workspacePadding = 5;
            textSize = 15;
        } else {
            barHeight = 34;
            horizontalPadding = 12;
            spacing = 8;
            pillVerticalPadding = 3;
            workspacePadding = 4;
            textSize = 14;
        }
    }

    property var settingsFile: FileView {
        id: settingsFile

        path: Qt.resolvedUrl("appearance.json")
        atomicWrites: true
        watchChanges: true

        onFileChanged: reload()
        onAdapterUpdated: writeAdapter()

        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound)
                writeAdapter();
        }

        adapter: JsonAdapter {
            id: settings

            property int barHeight: 32
            property string activeBarProfile: "work"
            property var barProfiles: ({
                "minimal": {
                    "densityPreset": "compact",
                    "barHeight": 30,
                    "horizontalPadding": 10,
                    "spacing": 4,
                    "radius": 6,
                    "workspaceButtonSize": 18,
                    "textSize": 13,
                    "archButtonHorizontalPadding": 5,
                    "activeWorkspaceHorizontalPadding": 5,
                    "pillVerticalPadding": 2,
                    "workspacePadding": 3,
                    "workspaceGlyphsEnabled": false,
                    "hideEmptyWorkspaces": true,
                    "workspaceAppCountVisible": false,
                    "workspaceGlyphs": ["", "", "", "", "", "", "", "", "", "",
                        "", "", "", "", "", "", "", "", "", ""],
                    "pillsTransparent": true,
                    "transparentBarTopMargin": 6,
                    "transparentBarSlanted": false,
                    "statusIsland": false,
                    "statusIslandRadius": 12,
                    "barTransparent": true,
                    "barTransparentBorder": true,
                    "statusModuleOrder": ["notifications", "recording", "audio", "network", "battery", "clock"],
                    "statusModuleEnabled": {
                        "notifications": true, "recording": true, "media": false, "audio": true,
                        "bluetooth": false, "tray": false,
                        "network": true, "battery": true, "clock": true
                    },
                    "statusModuleGroups": {},
                    "statusModulePlacement": {},
                    "barElementEnabled": {
                        "arch": true, "system": false, "currentApp": false, "workspaces": true
                    },
                    "barElementPlacement": {}
                },
                "work": {},
                "media": {
                    "densityPreset": "balanced",
                    "barHeight": 34,
                    "horizontalPadding": 12,
                    "spacing": 8,
                    "radius": 8,
                    "workspaceButtonSize": 20,
                    "textSize": 14,
                    "archButtonHorizontalPadding": 6,
                    "activeWorkspaceHorizontalPadding": 6,
                    "pillVerticalPadding": 3,
                    "workspacePadding": 4,
                    "workspaceGlyphsEnabled": false,
                    "hideEmptyWorkspaces": false,
                    "workspaceAppCountVisible": true,
                    "workspaceGlyphs": ["", "", "", "", "", "", "", "", "", "",
                        "", "", "", "", "", "", "", "", "", ""],
                    "pillsTransparent": false,
                    "transparentBarTopMargin": 7,
                    "transparentBarSlanted": false,
                    "statusIsland": true,
                    "statusIslandRadius": 14,
                    "barTransparent": true,
                    "barTransparentBorder": true,
                    "statusModuleOrder": ["notifications", "recording", "media", "audio", "network", "battery", "clock"],
                    "statusModuleEnabled": {
                        "notifications": true, "recording": true, "media": true, "audio": true,
                        "bluetooth": false, "tray": false,
                        "network": true, "battery": true, "clock": true
                    },
                    "statusModuleGroups": { "media": 1, "audio": 1 },
                    "statusModulePlacement": { "media": "center" },
                    "barElementEnabled": {
                        "arch": true, "system": true, "currentApp": true, "workspaces": true
                    },
                    "barElementPlacement": {}
                },
                "presentation": {
                    "densityPreset": "compact",
                    "barHeight": 30,
                    "horizontalPadding": 12,
                    "spacing": 5,
                    "radius": 6,
                    "workspaceButtonSize": 18,
                    "textSize": 13,
                    "archButtonHorizontalPadding": 5,
                    "activeWorkspaceHorizontalPadding": 5,
                    "pillVerticalPadding": 2,
                    "workspacePadding": 3,
                    "workspaceGlyphsEnabled": false,
                    "hideEmptyWorkspaces": true,
                    "workspaceAppCountVisible": false,
                    "workspaceGlyphs": ["", "", "", "", "", "", "", "", "", "",
                        "", "", "", "", "", "", "", "", "", ""],
                    "pillsTransparent": true,
                    "transparentBarTopMargin": 8,
                    "transparentBarSlanted": false,
                    "statusIsland": false,
                    "statusIslandRadius": 12,
                    "barTransparent": true,
                    "barTransparentBorder": true,
                    "statusModuleOrder": ["notifications", "recording", "network", "battery", "clock"],
                    "statusModuleEnabled": {
                        "notifications": true, "recording": true, "media": false, "audio": false,
                        "bluetooth": false, "tray": false,
                        "network": true, "battery": true, "clock": true
                    },
                    "statusModuleGroups": {},
                    "statusModulePlacement": {},
                    "barElementEnabled": {
                        "arch": false, "system": false, "currentApp": false, "workspaces": false
                    },
                    "barElementPlacement": {}
                }
            })
            property string densityPreset: "balanced"
            property int horizontalPadding: 12
            property int spacing: 8
            property int radius: 8
            property int workspaceButtonSize: 20
            property int textSize: 14
            property int archButtonHorizontalPadding: 6
            property int activeWorkspaceHorizontalPadding: 6
            property int pillVerticalPadding: 3
            property int workspacePadding: 4
            property bool workspaceGlyphsEnabled: false
            property bool hideEmptyWorkspaces: false
            property bool workspaceAppCountVisible: true
            property var workspaceGlyphs: [
                "", "", "", "", "", "", "", "", "", "",
                "", "", "", "", "", "", "", "", "", ""
            ]
            property bool pillsTransparent: false
            property int transparentBarTopMargin: 0
            property bool transparentBarSlanted: false
            property bool statusIsland: false
            property int statusIslandRadius: 12
            property bool backgroundClockEnabled: true
            property bool backgroundClockCalendarEnabled: false
            property string backgroundClockPosition: "center"
            property int backgroundClockSize: 96
            property int backgroundClockOpacity: 100
            property string backgroundClockDateFormat: "full"
            property bool desktopMediaEnabled: false
            property string desktopMediaPosition: "bottom-left"
            property bool desktopSystemEnabled: false
            property string desktopSystemPosition: "top-right"
            property bool desktopCalendarEnabled: false
            property string desktopCalendarPosition: "top-left"
            property bool desktopNetworkEnabled: false
            property string desktopNetworkPosition: "bottom-right"
            property bool desktopWeatherEnabled: false
            property string desktopWeatherPosition: "top-center"
            property string desktopWeatherLocation: "Ourense, ES"
            property var desktopWidgetOrder: ["media", "system", "calendar", "network", "weather"]
            property var statusModuleOrder: [
                "notifications", "recording", "media", "audio", "bluetooth", "tray", "network",
                "battery", "clock"
            ]
            property var statusModuleEnabled: {
                "notifications": true,
                "recording": true,
                "media": true,
                "audio": true,
                "bluetooth": true,
                "tray": true,
                "network": true,
                "battery": true,
                "clock": true
            }
            property var statusModuleGroups: {}
            property var statusModulePlacement: {}
            property var barElementEnabled: {
                "arch": true,
                "system": true,
                "currentApp": true,
                "workspaces": true
            }
            property var barElementPlacement: {}
            property string notificationPopupLocation: "top-center"
            property bool doNotDisturb: false
            property bool barTransparent: false
            property bool barTransparentBorder: false
        }
    }
}
