import QtQuick
import Quickshell.Io
import "BarProfileModel.js" as BarProfileModel

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
    property alias structuralVerticalPadding: settings.structuralVerticalPadding
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
    property alias barElements: settings.barElements
    property alias statusModuleGroups: settings.statusModuleGroups
    property alias notificationPopupLocation: settings.notificationPopupLocation
    property alias doNotDisturb: settings.doNotDisturb
    property alias barTransparent: settings.barTransparent
    property alias barTransparentBorder: settings.barTransparentBorder
    property alias barOpacity: settings.barOpacity
    property alias notificationBadgeVisible: settings.notificationBadgeVisible
    property alias mediaTitleVisible: settings.mediaTitleVisible
    property alias audioMeterVisible: settings.audioMeterVisible
    property alias batteryPercentageVisible: settings.batteryPercentageVisible

    function applyChanges(changes) {
        if (!changes)
            return;

        for (const key in changes)
            settings[key] = changes[key];
    }

    function applyBarProfile(profileName) {
        applyChanges(BarProfileModel.applyProfile(settings, profileName));
    }

    function saveBarProfile(profileName) {
        applyChanges(BarProfileModel.saveProfile(settings, profileName));
    }

    function barProfileValue(profileName, key) {
        return BarProfileModel.profileValue(settings, profileName, key);
    }

    function applyDensityPreset(preset) {
        applyChanges(BarProfileModel.densityPresetChanges(preset));
    }

    function liveBarElements() {
        return BarProfileModel.normalizeBarElements(settings.barElements);
    }

    function setBarElementEnabled(element, enabled) {
        settings.barElements = BarProfileModel.setElementEnabled(liveBarElements(), element, enabled);
    }

    function moveBarElement(element, offset) {
        settings.barElements = BarProfileModel.moveElement(liveBarElements(), element, offset);
    }

    function moveBarElementToZone(element, zone) {
        settings.barElements = BarProfileModel.moveElementToZone(liveBarElements(), element, zone);
    }

    // Files written before bar elements existed get the element order step.
    function migrateLoadedFile() {
        let raw = null;

        try {
            raw = JSON.parse(settingsFile.text());
        } catch (error) {
            return;
        }

        if (!raw || raw.barElements !== undefined)
            return;

        const migrated = BarProfileModel.migrateElementOrder(raw);
        applyChanges({
            barElements: migrated.barElements,
            barProfiles: migrated.barProfiles
        });
    }

    property var settingsFile: FileView {
        id: settingsFile

        path: Qt.resolvedUrl("appearance.json")
        atomicWrites: true
        watchChanges: true

        onFileChanged: reload()
        onAdapterUpdated: writeAdapter()
        onLoaded: migrateLoadedFile()

        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound) {
                settings.barProfiles = BarProfileModel.migrateElementOrder({
                    barProfiles: settings.barProfiles
                }).barProfiles;
                writeAdapter();
            }
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
            property int structuralVerticalPadding: 5
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
            property var statusModuleGroups: ({})
            property var barElements: ({
                "left": [
                    { "id": "arch", "enabled": true },
                    { "id": "systemMonitor", "enabled": true },
                    { "id": "currentApp", "enabled": true }
                ],
                "center": [
                    { "id": "workspaces", "enabled": true }
                ],
                "right": [
                    { "id": "notifications", "enabled": true },
                    { "id": "recording", "enabled": true },
                    { "id": "media", "enabled": true },
                    { "id": "audio", "enabled": true },
                    { "id": "bluetooth", "enabled": true },
                    { "id": "tray", "enabled": true },
                    { "id": "network", "enabled": true },
                    { "id": "battery", "enabled": true },
                    { "id": "clock", "enabled": true }
                ]
            })
            property string notificationPopupLocation: "top-center"
            property bool doNotDisturb: false
            property bool barTransparent: false
            property bool barTransparentBorder: false
            property int barOpacity: 100
            property bool notificationBadgeVisible: true
            property bool mediaTitleVisible: true
            property bool audioMeterVisible: true
            property bool batteryPercentageVisible: true
        }
    }
}
