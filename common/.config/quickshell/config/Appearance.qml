import QtQuick
import Quickshell.Io
import "BarProfileModel.js" as BarProfileModel
import "SchemaMigrations.js" as SchemaMigrations

QtObject {
    id: root

    property alias schemaVersion: settings.schemaVersion
    property alias barHeight: settings.barHeight
    property alias editingBarProfile: settings.editingBarProfile
    property alias barProfiles: settings.barProfiles
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
    property alias groupRadius: settings.groupRadius
    property alias barElements: settings.barElements
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

    // The edited profile has pending changes: the live settings differ from
    // what it saves. Only monitors drawing it show them.
    readonly property bool barProfileModified: BarProfileModel.isModified(settings)

    // Picks the profile the settings panel edits; no monitor changes. Ignored
    // while the edited profile has pending changes.
    function editBarProfile(profileName) {
        applyChanges(BarProfileModel.editProfile(settings, profileName));
    }

    // Writes the pending changes into the edited profile.
    function saveBarProfile() {
        applyChanges(BarProfileModel.saveProfile(settings, settings.editingBarProfile));
    }

    // Drops the pending changes: back to the saved edited profile.
    function discardBarProfileChanges() {
        applyChanges(BarProfileModel.discardChanges(settings));
    }

    // Copies the edited profile as `newName` and edits the copy. Ignored with
    // pending changes or a name duplicateNameError refuses.
    function duplicateBarProfile(newName) {
        applyChanges(BarProfileModel.duplicateProfile(settings, settings.editingBarProfile, newName));
    }

    // Removes `profileName` unless deleteBarProfileRejection refuses;
    // `displaySettings` comes from monitors.json.
    function deleteBarProfile(profileName, displaySettings) {
        applyChanges(BarProfileModel.deleteProfile(settings, displaySettings, profileName));
    }

    function suggestedDuplicateName() {
        return BarProfileModel.suggestedDuplicateName(settings, settings.editingBarProfile);
    }

    function duplicateNameError(newName) {
        return BarProfileModel.duplicateNameError(settings, newName);
    }

    function deleteBarProfileRejection(profileName, displaySettings) {
        return BarProfileModel.deleteRejection(settings, displaySettings, profileName);
    }

    function barProfileValue(profileName, key) {
        return BarProfileModel.profileValue(settings, profileName, key);
    }

    // The density preset the live sizes match ("" if none): presets are a
    // shortcut, so the matching one is derived instead of stored.
    readonly property string matchingDensityPreset: BarProfileModel.matchingDensityPreset(settings)

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

    function setBarElementJoined(element, joined) {
        settings.barElements = BarProfileModel.setElementJoined(liveBarElements(), element, joined);
    }

    function moveBarElementToZone(element, zone) {
        settings.barElements = BarProfileModel.moveElementToZone(liveBarElements(), element, zone);
    }

    property bool loaded: false

    // Pending changes live in memory only: the live settings in the file are a
    // buffer, so the first load in the current schema drops them (one write).
    property bool pendingChangesDropped: false

    function dropPendingChangesOnStart() {
        if (pendingChangesDropped || settings.schemaVersion !== SchemaMigrations.schemaVersion)
            return;

        pendingChangesDropped = true;
        const state = rawState();
        if (!state || !state.barProfiles)
            return;

        // Nothing to write unless there were pending changes or profiles that
        // had to be completed (see BarProfileModel.loadProfile).
        const changes = BarProfileModel.discardChanges(state);
        if (!BarProfileModel.isModified(state) && !changes.barProfiles)
            return;

        for (const key in changes)
            state[key] = changes[key];
        settingsFile.setText(JSON.stringify(state, null, 4));
    }

    // The file as stored, including keys the adapter does not declare; null
    // when it is empty or unreadable.
    function rawState() {
        try {
            return JSON.parse(settingsFile.text());
        } catch (error) {
            return null;
        }
    }

    // Replaces the file with a migrated state (see SchemaMigration) in a
    // single write, which the adapter then loads; per-property writes would
    // race with reloads.
    function applyMigratedState(state) {
        settingsFile.setText(JSON.stringify(state, null, 4));
    }

    property var settingsFile: FileView {
        id: settingsFile

        path: Qt.resolvedUrl("appearance.json")
        atomicWrites: true
        watchChanges: true

        onFileChanged: reload()
        onAdapterUpdated: writeAdapter()
        onLoaded: {
            root.loaded = true;
            root.dropPendingChangesOnStart();
        }

        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound) {
                // A new file starts from the defaults, in the current schema.
                settings.barProfiles = SchemaMigrations.migrateGroups(
                    SchemaMigrations.migrateElementOrder({
                        barProfiles: settings.barProfiles
                    })).barProfiles;
                settings.schemaVersion = SchemaMigrations.schemaVersion;
                writeAdapter();
            }
            root.pendingChangesDropped = true;
            root.loaded = true;
        }

        adapter: JsonAdapter {
            id: settings

            property int schemaVersion: 0
            property int barHeight: 32
            property string editingBarProfile: BarProfileModel.defaultBarProfile
            property var barProfiles: ({
                "minimal": {
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
            property int groupRadius: 8
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
