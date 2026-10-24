import QtQuick
import "." as Panels

Column {
    id: root

    property var appearance
    property var plugins

    width: parent ? parent.width : 0
    spacing: 14

    Panels.SettingsHint {
        width: parent.width
        appearance: root.appearance
        text: "Disabled plugins no longer open from their keyboard shortcut or shell actions."
    }

    Panels.SettingsHeading {
        appearance: root.appearance
        text: "Plugins"
        topPadding: 4
    }

    // A list, so it stays full width: each plugin's switch row with what the
    // plugin does underneath.
    Column {
        width: parent.width
        spacing: 2

        Repeater {
            model: [
                { label: "Application launcher", propertyName: "applicationLauncherEnabled",
                  description: "Browse, search, favorite, and launch desktop applications." },
                { label: "Clipboard history", propertyName: "clipboardEnabled",
                  description: "Search copied content and manage pinned clipboard entries." },
                { label: "Quick search", propertyName: "quickSearchEnabled",
                  description: "Open bookmarks and search the web from a compact prompt." },
                { label: "Unified search", propertyName: "unifiedSearchEnabled",
                  description: "Search applications, windows, bookmarks, actions, and clipboard history." },
                { label: "Quick settings", propertyName: "quickSettingsEnabled",
                  description: "Access audio, connectivity, appearance, and session actions." },
                { label: "Command launcher", propertyName: "commandLauncherEnabled",
                  description: "Run a shell command in the configured terminal." },
                { label: "Screen capture", propertyName: "screenCaptureEnabled",
                  description: "Choose screenshot and screen recording actions." },
                { label: "Control center", propertyName: "controlCenterEnabled",
                  description: "Open the expanded system and media control panel." }
            ]

            delegate: Column {
                required property var modelData

                width: parent.width

                Panels.SettingsSwitchRow {
                    width: parent.width
                    appearance: root.appearance
                    label: modelData.label
                    checked: root.plugins[modelData.propertyName]
                    onToggled: root.plugins[modelData.propertyName] = !root.plugins[modelData.propertyName]
                }

                Panels.SettingsHint {
                    x: 12
                    width: parent.width - 24
                    bottomPadding: 6
                    appearance: root.appearance
                    text: modelData.description
                }
            }
        }
    }

    Panels.SettingsHeading {
        appearance: root.appearance
        text: "Plugin settings"
        topPadding: 8
    }

    Panels.SettingsGrid {
        Panels.SettingsNumber {
            width: parent.cellWidth
            appearance: root.appearance
            label: "Launcher recent apps"
            from: 0
            to: 50
            value: root.plugins.launcherRecentLimit
            onEdited: number => root.plugins.launcherRecentLimit = number
        }

        Panels.SettingsSwitchRow {
            width: parent.cellWidth
            appearance: root.appearance
            label: "Clipboard image previews"
            checked: root.plugins.clipboardImagePreviewsEnabled
            onToggled: root.plugins.clipboardImagePreviewsEnabled = !root.plugins.clipboardImagePreviewsEnabled
        }
    }
}
