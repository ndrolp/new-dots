import QtQuick
import Quickshell.Io
import "BarProfileModel.js" as BarProfileModel
import "SchemaMigrations.js" as SchemaMigrations

// Saved bar profiles and global settings (appearance.json), plus the bar
// profile the settings panel edits and its pending changes, which live in
// memory only (see BarProfileModel).
QtObject {
    id: root

    property alias schemaVersion: settings.schemaVersion
    property alias barProfiles: settings.barProfiles
    property alias notificationPopupLocation: settings.notificationPopupLocation
    property alias doNotDisturb: settings.doNotDisturb

    // Not stored: a restart edits the default profile with nothing pending.
    property string editingBarProfile: ""
    property var pendingProfile: null

    readonly property var barProfileState: ({
        barProfiles: settings.barProfiles,
        editingBarProfile: root.editingBarProfile,
        pendingProfile: root.pendingProfile
    })

    // The edited profile with its pending changes. The settings panel reads
    // the bar settings below from it and changes them with setBarSetting.
    readonly property var editedBarProfile: BarProfileModel.editedProfile(barProfileState)

    readonly property int barHeight: editedBarProfile.barHeight
    readonly property int horizontalPadding: editedBarProfile.horizontalPadding
    readonly property int spacing: editedBarProfile.spacing
    readonly property int radius: editedBarProfile.radius
    readonly property int workspaceButtonSize: editedBarProfile.workspaceButtonSize
    readonly property int textSize: editedBarProfile.textSize
    readonly property int archButtonHorizontalPadding: editedBarProfile.archButtonHorizontalPadding
    readonly property int activeWorkspaceHorizontalPadding: editedBarProfile.activeWorkspaceHorizontalPadding
    readonly property int pillVerticalPadding: editedBarProfile.pillVerticalPadding
    readonly property int workspacePadding: editedBarProfile.workspacePadding
    readonly property int elementVerticalPadding: editedBarProfile.elementVerticalPadding
    readonly property bool pillsTransparent: editedBarProfile.pillsTransparent
    readonly property int transparentBarTopMargin: editedBarProfile.transparentBarTopMargin
    readonly property bool transparentBarSlanted: editedBarProfile.transparentBarSlanted
    readonly property int groupRadius: editedBarProfile.groupRadius
    readonly property var barElements: editedBarProfile.barElements
    readonly property bool barTransparent: editedBarProfile.barTransparent
    readonly property bool barTransparentBorder: editedBarProfile.barTransparentBorder
    readonly property int barOpacity: editedBarProfile.barOpacity

    // Applies changes returned by BarProfileModel: saved profiles go to the
    // file, the edited profile and pending changes stay in memory.
    function applyChanges(changes) {
        if (!changes)
            return;

        if (changes.barProfiles !== undefined)
            settings.barProfiles = changes.barProfiles;
        if (changes.editingBarProfile !== undefined)
            root.editingBarProfile = changes.editingBarProfile;
        if (changes.pendingProfile !== undefined)
            root.pendingProfile = changes.pendingProfile;
    }

    // Sets a bar setting of the edited profile, as a pending change.
    function setBarSetting(key, value) {
        const values = {};
        values[key] = value;
        applyChanges(BarProfileModel.setValues(barProfileState, values));
    }

    // The edited profile has pending changes. Only monitors drawing it show them.
    readonly property bool barProfileModified: BarProfileModel.isModified(barProfileState)

    // Picks the profile the settings panel edits; no monitor changes. Ignored
    // while the edited profile has pending changes.
    function editBarProfile(profileName) {
        applyChanges(BarProfileModel.editProfile(barProfileState, profileName));
    }

    // Writes the pending changes into the edited profile.
    function saveBarProfile() {
        applyChanges(BarProfileModel.saveProfile(barProfileState));
    }

    // Drops the pending changes: back to the saved edited profile.
    function discardBarProfileChanges() {
        applyChanges(BarProfileModel.discardChanges(barProfileState));
    }

    // Copies the edited profile as `newName` and edits the copy. Ignored with
    // pending changes or a name duplicateNameError refuses.
    function duplicateBarProfile(newName) {
        applyChanges(BarProfileModel.duplicateProfile(barProfileState, editingBarProfile, newName));
    }

    // Removes `profileName` unless deleteBarProfileRejection refuses;
    // `displaySettings` comes from monitors.json.
    function deleteBarProfile(profileName, displaySettings) {
        applyChanges(BarProfileModel.deleteProfile(barProfileState, displaySettings, profileName));
    }

    function suggestedDuplicateName() {
        return BarProfileModel.suggestedDuplicateName(barProfileState, editingBarProfile);
    }

    function duplicateNameError(newName) {
        return BarProfileModel.duplicateNameError(barProfileState, newName);
    }

    function deleteBarProfileRejection(profileName, displaySettings) {
        return BarProfileModel.deleteRejection(barProfileState, displaySettings, profileName);
    }

    // What a monitor drawing `profileName` shows for `key`.
    function barProfileValue(profileName, key) {
        return BarProfileModel.profileValue(barProfileState, profileName, key);
    }

    // The density preset the edited sizes match ("" if none): presets are a
    // shortcut, so the matching one is derived instead of stored.
    readonly property string matchingDensityPreset: BarProfileModel.matchingDensityPreset(editedBarProfile)

    function applyDensityPreset(preset) {
        applyChanges(BarProfileModel.setValues(barProfileState,
            BarProfileModel.densityPresetChanges(preset)));
    }

    function setBarElementEnabled(element, enabled) {
        setBarSetting("barElements", BarProfileModel.setElementEnabled(barElements, element, enabled));
    }

    function moveBarElement(element, offset) {
        setBarSetting("barElements", BarProfileModel.moveElement(barElements, element, offset));
    }

    function setBarElementJoined(element, joined) {
        setBarSetting("barElements", BarProfileModel.setElementJoined(barElements, element, joined));
    }

    // An option of a bar element of the edited profile (see
    // BarProfileModel.elementOptionDefaults).
    function barElementOption(element, option) {
        return BarProfileModel.elementOption(barElements, element, option);
    }

    function setBarElementOption(element, option, value) {
        setBarSetting("barElements", BarProfileModel.setElementOption(barElements, element,
            option, value));
    }

    function moveBarElementToZone(element, zone) {
        setBarSetting("barElements", BarProfileModel.moveElementToZone(barElements, element, zone));
    }

    // Keeps the edited profile one that exists, e.g. after the first load or
    // when another instance deleted it.
    function ensureEditedProfile() {
        if (settings.barProfiles[editingBarProfile] !== undefined)
            return;

        editingBarProfile = BarProfileModel.defaultProfileName(settings.barProfiles);
        pendingProfile = null;
    }

    property bool loaded: false

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
            root.ensureEditedProfile();
            root.loaded = true;
        }

        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound) {
                // The defaults are already in the current schema.
                settings.schemaVersion = SchemaMigrations.schemaVersion;
                writeAdapter();
            }
            root.ensureEditedProfile();
            root.loaded = true;
        }

        adapter: JsonAdapter {
            id: settings

            property int schemaVersion: 0
            property var barProfiles: BarProfileModel.defaultBarProfiles()
            property string notificationPopupLocation: "top-center"
            property bool doNotDisturb: false
        }
    }
}
