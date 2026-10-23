import QtQuick
import QtQuick.Controls
import "../../config" as Config
import "../../config/BarProfileModel.js" as BarProfileModel

// The bar profile being edited, its "modified" indicator, Save/Discard and
// Duplicate/Delete. While there are pending changes the selector, Duplicate
// and Delete are locked.
Column {
    id: root

    property var appearance
    // Config.Monitors: Delete is refused for profiles a monitor draws.
    property var monitors
    readonly property bool modified: appearance.barProfileModified
    readonly property var profileNames: Object.keys(appearance.barProfiles || {}).sort()
    readonly property var displaySettings: monitors ? monitors.displaySettings : ({})

    // "" (none), "duplicate" (naming the copy) or "delete" (confirming or
    // explaining why the edited profile cannot be deleted).
    property string action: ""
    readonly property string duplicateError: appearance.duplicateNameError(duplicateName.text)
    readonly property string deleteRejection: appearance.deleteBarProfileRejection(
        appearance.editingBarProfile, displaySettings)

    function displayName(profileName) {
        return profileName.length > 0
            ? profileName.charAt(0).toUpperCase() + profileName.slice(1) : "";
    }

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
            return "Can't delete \"" + displayName(appearance.editingBarProfile)
                + "\": used by " + BarProfileModel.monitorsUsingProfile(
                    displaySettings, appearance.editingBarProfile).join(", ")
                + ". Assign another profile to them first.";
        if (deleteRejection === "last")
            return "Can't delete the last bar profile.";
        if (deleteRejection === "pending")
            return "Save or discard the pending changes first.";
        return "Delete \"" + displayName(appearance.editingBarProfile) + "\"? This can't be undone.";
    }

    onModifiedChanged: if (modified) action = ""

    width: parent ? parent.width : 0
    spacing: 6

    Config.Theme {
        id: theme
    }

    Rectangle {
        width: parent.width
        height: 44
        radius: root.appearance.radius
        color: profileHover.hovered ? theme.surfaceHover : theme.backgroundSecondary

        HoverHandler {
            id: profileHover
        }

        Row {
            anchors.left: parent.left
            anchors.leftMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "EDITING PROFILE"
                color: theme.text
                font.pixelSize: root.appearance.textSize - 1
                font.bold: true
            }

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                visible: root.modified
                width: modifiedLabel.implicitWidth + 12
                height: modifiedLabel.implicitHeight + 4
                radius: height / 2
                color: theme.surface
                border.width: 1
                border.color: theme.accent

                Text {
                    id: modifiedLabel

                    anchors.centerIn: parent
                    text: "modified"
                    color: theme.accent
                    font.pixelSize: root.appearance.textSize - 3
                    font.bold: true
                }
            }
        }

        Row {
            anchors.right: parent.right
            anchors.rightMargin: 6
            anchors.verticalCenter: parent.verticalCenter
            spacing: 6

            ComboBox {
                id: profileSelector

                width: 132
                height: 32
                enabled: !root.modified
                opacity: enabled ? 1 : 0.6
                model: root.profileNames
                currentIndex: root.profileNames.indexOf(root.appearance.editingBarProfile)
                displayText: root.displayName(currentText)

                contentItem: Text {
                    leftPadding: 10
                    rightPadding: 8
                    verticalAlignment: Text.AlignVCenter
                    text: profileSelector.displayText
                    color: theme.accent
                    elide: Text.ElideRight
                    font.pixelSize: root.appearance.textSize - 1
                    font.bold: true
                }

                indicator: Item {}

                background: Rectangle {
                    radius: root.appearance.radius
                    color: theme.surface
                }

                onActivated: index => {
                    root.action = "";
                    root.appearance.editBarProfile(root.profileNames[index]);
                }
            }

            Repeater {
                model: root.modified ? [] : [
                    { label: "Duplicate", action: "duplicate", width: 76 },
                    { label: "Delete", action: "delete", width: 58 }
                ]

                delegate: Rectangle {
                    id: actionButton

                    required property var modelData

                    width: modelData.width
                    height: 32
                    radius: root.appearance.radius
                    color: root.action === modelData.action || actionHover.hovered
                        ? theme.surfaceHover : theme.surface

                    HoverHandler {
                        id: actionHover
                    }

                    Text {
                        anchors.centerIn: parent
                        text: actionButton.modelData.label
                        color: actionButton.modelData.action === "delete" ? theme.red : theme.text
                        font.pixelSize: root.appearance.textSize - 3
                        font.bold: true
                    }

                    TapHandler {
                        onTapped: {
                            if (root.action === actionButton.modelData.action)
                                root.action = "";
                            else if (actionButton.modelData.action === "duplicate")
                                root.startDuplicate();
                            else
                                root.action = "delete";
                        }
                    }
                }
            }

            Rectangle {
                visible: root.modified
                width: 64
                height: 32
                radius: root.appearance.radius
                color: discardHover.hovered ? theme.surfaceHover : theme.surface

                HoverHandler {
                    id: discardHover
                }

                Text {
                    anchors.centerIn: parent
                    text: "Discard"
                    color: theme.text
                    font.pixelSize: root.appearance.textSize - 3
                    font.bold: true
                }

                TapHandler {
                    onTapped: root.appearance.discardBarProfileChanges()
                }
            }

            Rectangle {
                width: 48
                height: 32
                radius: root.appearance.radius
                opacity: root.modified ? 1 : 0.5
                color: saveHover.hovered && root.modified ? theme.accentHover : theme.accent

                HoverHandler {
                    id: saveHover
                }

                Text {
                    anchors.centerIn: parent
                    text: "Save"
                    color: theme.background
                    font.pixelSize: root.appearance.textSize - 3
                    font.bold: true
                }

                TapHandler {
                    enabled: root.modified
                    onTapped: root.appearance.saveBarProfile()
                }
            }
        }
    }

    Row {
        visible: root.action === "duplicate"
        width: parent.width
        spacing: 6

        SettingsInput {
            id: duplicateName

            width: parent.width - createButton.width - cancelDuplicate.width - parent.spacing * 2
            appearance: root.appearance
            placeholderText: "New profile name"
            onAccepted: root.confirmDuplicate()
            Keys.onEscapePressed: root.action = ""
        }

        Rectangle {
            id: createButton

            width: 64
            height: 36
            radius: root.appearance.radius
            opacity: root.duplicateError === "" ? 1 : 0.5
            color: createHover.hovered && root.duplicateError === "" ? theme.accentHover : theme.accent

            HoverHandler {
                id: createHover
            }

            Text {
                anchors.centerIn: parent
                text: "Create"
                color: theme.background
                font.pixelSize: root.appearance.textSize - 3
                font.bold: true
            }

            TapHandler {
                enabled: root.duplicateError === ""
                onTapped: root.confirmDuplicate()
            }
        }

        Rectangle {
            id: cancelDuplicate

            width: 64
            height: 36
            radius: root.appearance.radius
            color: cancelDuplicateHover.hovered ? theme.surfaceHover : theme.surface

            HoverHandler {
                id: cancelDuplicateHover
            }

            Text {
                anchors.centerIn: parent
                text: "Cancel"
                color: theme.text
                font.pixelSize: root.appearance.textSize - 3
                font.bold: true
            }

            TapHandler {
                onTapped: root.action = ""
            }
        }
    }

    Text {
        visible: root.action === "duplicate" && root.duplicateError !== ""
        width: parent.width
        text: root.duplicateError === "empty"
            ? "Enter a name for the copy."
            : "A profile with that name already exists."
        color: theme.red
        wrapMode: Text.WordWrap
        font.pixelSize: root.appearance.textSize - 2
    }

    Row {
        visible: root.action === "delete"
        width: parent.width
        spacing: 6

        Text {
            width: parent.width - (confirmDeleteButton.visible ? confirmDeleteButton.width
                + cancelDelete.width + parent.spacing * 2 : 0)
            anchors.verticalCenter: parent.verticalCenter
            text: root.deleteMessage()
            color: root.deleteRejection === "" ? theme.text : theme.red
            wrapMode: Text.WordWrap
            font.pixelSize: root.appearance.textSize - 2
        }

        Rectangle {
            id: confirmDeleteButton

            visible: root.deleteRejection === ""
            width: 64
            height: 32
            radius: root.appearance.radius
            color: theme.red

            Text {
                anchors.centerIn: parent
                text: "Delete"
                color: theme.background
                font.pixelSize: root.appearance.textSize - 3
                font.bold: true
            }

            TapHandler {
                onTapped: root.confirmDelete()
            }
        }

        Rectangle {
            id: cancelDelete

            visible: root.deleteRejection === ""
            width: 64
            height: 32
            radius: root.appearance.radius
            color: cancelDeleteHover.hovered ? theme.surfaceHover : theme.surface

            HoverHandler {
                id: cancelDeleteHover
            }

            Text {
                anchors.centerIn: parent
                text: "Cancel"
                color: theme.text
                font.pixelSize: root.appearance.textSize - 3
                font.bold: true
            }

            TapHandler {
                onTapped: root.action = ""
            }
        }
    }

    Text {
        width: parent.width
        text: root.modified
            ? "Unsaved changes show only on monitors using this profile. Save or discard them to edit another profile."
            : "Changes show live on monitors using this profile until you save or discard them."
        color: theme.textMuted
        wrapMode: Text.WordWrap
        font.pixelSize: root.appearance.textSize - 2
    }
}
