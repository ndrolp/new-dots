import QtQuick
import "." as Panels
import "../../config" as Config
import "../../config/BarProfileModel.js" as BarProfileModel

// The bar profile being edited, as a choice between the bar profiles, its
// "modified" indicator, Save/Discard and Duplicate/Delete. While there are
// pending changes the choice is locked and Duplicate and Delete are hidden.
Column {
    id: root

    property var appearance
    // Config.Monitors: Delete is refused for profiles a monitor draws.
    property var monitors
    readonly property bool modified: appearance.barProfileModified
    readonly property var profileChoices: BarProfileModel.profileChoices(appearance.barProfiles)
    readonly property var displaySettings: monitors ? monitors.displaySettings : ({})

    // "" (none), "duplicate" (naming the copy) or "delete" (confirming or
    // explaining why the edited profile cannot be deleted).
    property string action: ""
    readonly property string duplicateError: appearance.duplicateNameError(duplicateName.text)
    readonly property string deleteRejection: appearance.deleteBarProfileRejection(
        appearance.editingBarProfile, displaySettings)

    function startDuplicate() {
        duplicateName.text = appearance.suggestedDuplicateName();
        action = "duplicate";
        duplicateName.forceActiveFocus();
        duplicateName.selectAll();
    }

    function confirmDuplicate() {
        if (duplicateError !== "")
            return;
        appearance.duplicateBarProfile(duplicateName.text);
        action = "";
    }

    function confirmDelete() {
        if (deleteRejection !== "")
            return;
        appearance.deleteBarProfile(appearance.editingBarProfile, displaySettings);
        action = "";
    }

    function deleteMessage() {
        if (deleteRejection === "assigned")
            return "Can't delete \"" + BarProfileModel.profileDisplayName(appearance.editingBarProfile)
                + "\": used by " + BarProfileModel.monitorsUsingProfile(
                    displaySettings, appearance.editingBarProfile).join(", ")
                + ". Assign another profile to them first.";
        if (deleteRejection === "last")
            return "Can't delete the last bar profile.";
        if (deleteRejection === "pending")
            return "Save or discard the pending changes first.";
        return "Delete \"" + BarProfileModel.profileDisplayName(appearance.editingBarProfile) + "\"? This can't be undone.";
    }

    onModifiedChanged: if (modified) action = ""

    width: parent ? parent.width : 0
    spacing: 10

    Config.Theme {
        id: theme
    }

    Row {
        spacing: 8

        Panels.SettingsLabel {
            appearance: root.appearance
            text: "Editing profile"
        }

        Panels.SettingsHint {
            visible: root.modified
            appearance: root.appearance
            text: "modified"
            color: theme.accent
        }
    }

    Item {
        width: parent.width
        height: Math.max(profileChoice.height, profileActions.height)

        Panels.SettingsChoice {
            id: profileChoice

            anchors.verticalCenter: parent.verticalCenter
            width: Math.min(root.profileChoices.length * 96,
                parent.width - profileActions.width - 12)
            appearance: root.appearance
            enabled: !root.modified
            opacity: enabled ? 1 : 0.6
            options: root.profileChoices
            value: root.appearance.editingBarProfile
            onChosen: profile => {
                root.action = "";
                root.appearance.editBarProfile(profile);
            }
        }

        Row {
            id: profileActions

            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 4

            Panels.SettingsButton {
                visible: !root.modified
                appearance: root.appearance
                label: "Duplicate"
                onActivated: root.action === "duplicate" ? root.action = "" : root.startDuplicate()
            }

            Panels.SettingsButton {
                visible: !root.modified
                appearance: root.appearance
                label: "Delete"
                labelColor: theme.red
                onActivated: root.action = root.action === "delete" ? "" : "delete"
            }

            Panels.SettingsButton {
                visible: root.modified
                appearance: root.appearance
                label: "Discard"
                onActivated: root.appearance.discardBarProfileChanges()
            }

            Panels.SettingsButton {
                visible: root.modified
                appearance: root.appearance
                label: "Save"
                labelColor: theme.accent
                onActivated: root.appearance.saveBarProfile()
            }
        }
    }

    Row {
        visible: root.action === "duplicate"
        width: parent.width
        spacing: 4

        Panels.SettingsInput {
            id: duplicateName

            width: parent.width - createButton.width - cancelDuplicate.width - parent.spacing * 2 - 8
            appearance: root.appearance
            placeholderText: "New profile name"
            onAccepted: root.confirmDuplicate()
            Keys.onEscapePressed: root.action = ""
        }

        Item {
            width: 8
            height: 1
        }

        Panels.SettingsButton {
            id: createButton

            appearance: root.appearance
            label: "Create"
            labelColor: theme.accent
            enabled: root.duplicateError === ""
            onActivated: root.confirmDuplicate()
        }

        Panels.SettingsButton {
            id: cancelDuplicate

            appearance: root.appearance
            label: "Cancel"
            onActivated: root.action = ""
        }
    }

    Panels.SettingsHint {
        visible: root.action === "duplicate" && root.duplicateError !== ""
        width: parent.width
        appearance: root.appearance
        text: root.duplicateError === "empty"
            ? "Enter a name for the copy."
            : "A profile with that name already exists."
        color: theme.red
    }

    Row {
        visible: root.action === "delete"
        width: parent.width
        spacing: 4

        Panels.SettingsHint {
            width: parent.width - (confirmDeleteButton.visible ? confirmDeleteButton.width
                + cancelDelete.width + parent.spacing * 2 : 0)
            anchors.verticalCenter: parent.verticalCenter
            appearance: root.appearance
            text: root.deleteMessage()
            color: root.deleteRejection === "" ? theme.text : theme.red
        }

        Panels.SettingsButton {
            id: confirmDeleteButton

            visible: root.deleteRejection === ""
            appearance: root.appearance
            label: "Delete permanently"
            labelColor: theme.red
            onActivated: root.confirmDelete()
        }

        Panels.SettingsButton {
            id: cancelDelete

            visible: root.deleteRejection === ""
            appearance: root.appearance
            label: "Cancel"
            onActivated: root.action = ""
        }
    }

    Panels.SettingsHint {
        width: parent.width
        appearance: root.appearance
        text: root.modified
            ? "Unsaved changes show only on monitors using this profile. Save or discard them to edit another profile."
            : "Changes show live on monitors using this profile until you save or discard them."
    }
}
