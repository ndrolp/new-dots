import QtQuick
import QtQuick.Controls
import "../../config" as Config

Column {
    id: root

    property var appearance
    property var plugins

    width: parent ? parent.width : 0
    spacing: 12

    Config.Theme {
        id: theme
    }

    component PluginToggle: Rectangle {
        required property string label
        required property string description
        required property string propertyName

        width: root.width
        height: 54
        radius: root.appearance.radius
        color: toggleHover.hovered ? theme.surfaceHover : theme.backgroundSecondary

        HoverHandler {
            id: toggleHover
        }

        Column {
            anchors.left: parent.left
            anchors.leftMargin: 12
            anchors.right: toggleControl.left
            anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2

            Text {
                text: parent.parent.label
                color: theme.text
                font.pixelSize: root.appearance.textSize - 1
                font.bold: true
            }

            Text {
                width: parent.width
                text: parent.parent.description
                color: theme.textMuted
                elide: Text.ElideRight
                font.pixelSize: root.appearance.textSize - 2
            }
        }

        Rectangle {
            id: toggleControl

            anchors.right: parent.right
            anchors.rightMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            width: 48
            height: 28
            radius: root.appearance.radius
            color: root.plugins[parent.propertyName] ? theme.accent : theme.surface

            Rectangle {
                x: root.plugins[parent.parent.propertyName] ? parent.width - width - 3 : 3
                anchors.verticalCenter: parent.verticalCenter
                width: 22
                height: 22
                radius: 11
                color: theme.text

                Behavior on x {
                    NumberAnimation {
                        duration: 160
                        easing.type: Easing.OutCubic
                    }
                }
            }
        }

        TapHandler {
            onTapped: root.plugins[parent.propertyName] = !root.plugins[parent.propertyName]
        }
    }

    Text {
        width: parent.width
        text: "Disabled plugins no longer open from their keyboard shortcut or shell actions."
        wrapMode: Text.WordWrap
        color: theme.textMuted
        font.pixelSize: root.appearance.textSize - 1
    }

    PluginToggle {
        label: "APPLICATION LAUNCHER"
        description: "Browse, search, favorite, and launch desktop applications."
        propertyName: "applicationLauncherEnabled"
    }

    PluginToggle {
        label: "CLIPBOARD HISTORY"
        description: "Search copied content and manage pinned clipboard entries."
        propertyName: "clipboardEnabled"
    }

    PluginToggle {
        label: "QUICK SEARCH"
        description: "Open bookmarks and search the web from a compact prompt."
        propertyName: "quickSearchEnabled"
    }

    PluginToggle {
        label: "UNIFIED SEARCH"
        description: "Search applications, windows, bookmarks, actions, and clipboard history."
        propertyName: "unifiedSearchEnabled"
    }

    PluginToggle {
        label: "QUICK SETTINGS"
        description: "Access audio, connectivity, appearance, and session actions."
        propertyName: "quickSettingsEnabled"
    }

    PluginToggle {
        label: "COMMAND LAUNCHER"
        description: "Run a shell command in the configured terminal."
        propertyName: "commandLauncherEnabled"
    }

    PluginToggle {
        label: "SCREEN CAPTURE"
        description: "Choose screenshot and screen recording actions."
        propertyName: "screenCaptureEnabled"
    }

    PluginToggle {
        label: "CONTROL CENTER"
        description: "Open the expanded system and media control panel."
        propertyName: "controlCenterEnabled"
    }

    Rectangle {
        width: root.width
        height: 56
        radius: root.appearance.radius
        color: theme.backgroundSecondary

        Text {
            anchors.left: parent.left
            anchors.leftMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            text: "Launcher recent apps"
            color: theme.text
            font.pixelSize: root.appearance.textSize - 1
            font.bold: true
        }

        SpinBox {
            anchors.right: parent.right
            anchors.rightMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            from: 0
            to: 50
            value: root.plugins.launcherRecentLimit
            editable: true

            onValueModified: root.plugins.launcherRecentLimit = value
        }
    }

    PluginToggle {
        label: "CLIPBOARD IMAGE PREVIEWS"
        description: "Decode copied images for preview in clipboard history."
        propertyName: "clipboardImagePreviewsEnabled"
    }
}
