import QtQuick
import QtQuick.Controls
import "../../config" as Config

// The bar profile being edited, its "modified" indicator and Save/Discard.
// While there are pending changes the selector is locked.
Column {
    id: root

    property var appearance
    readonly property bool modified: appearance.barProfileModified
    readonly property var profileNames: Object.keys(appearance.barProfiles || {}).sort()

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
                displayText: currentText.length > 0
                    ? currentText.charAt(0).toUpperCase() + currentText.slice(1) : ""

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

                onActivated: index => root.appearance.editBarProfile(root.profileNames[index])
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
