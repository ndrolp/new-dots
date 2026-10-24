import QtQuick
import "." as Panels

// One monitor's settings in the Displays section: the workspaces it shows and
// what the shell draws on it. Kept apart from WorkspaceSettings, which lists
// the monitors through Quickshell.
Column {
    id: root

    property var appearance
    // Config.Monitors: reads and saves this monitor's settings.
    property var monitors
    property string monitorDescription: ""
    readonly property var range: monitors.rangeFor(monitorDescription)
    readonly property var displaySettings: monitors.displaySettingsFor(monitorDescription)

    width: parent ? parent.width : 0
    spacing: 14

    Panels.SettingsHeading {
        width: parent.width
        appearance: root.appearance
        text: root.monitorDescription
        topPadding: 4
    }

    Panels.SettingsGrid {
        Panels.SettingsNumber {
            width: parent.cellWidth
            appearance: root.appearance
            label: "First workspace"
            from: 1
            to: 20
            value: root.range.from
            onEdited: number => root.monitors.setRangeStart(root.monitorDescription, number)
        }

        Panels.SettingsNumber {
            width: parent.cellWidth
            appearance: root.appearance
            label: "Last workspace"
            from: 1
            to: 20
            value: root.range.to
            onEdited: number => root.monitors.setRangeEnd(root.monitorDescription, number)
        }

        Panels.SettingsSwitchRow {
            width: parent.cellWidth
            appearance: root.appearance
            label: "Show bar"
            checked: root.displaySettings.barVisible
            onToggled: root.monitors.setDisplaySetting(root.monitorDescription, "barVisible",
                !root.displaySettings.barVisible)
        }
    }

    Column {
        width: parent.width
        spacing: 6

        Panels.SettingsLabel {
            appearance: root.appearance
            text: "Bar profile"
        }

        Panels.SettingsChoice {
            width: Math.min(parent.width, 120 * Math.max(1, options.length))
            appearance: root.appearance
            options: Object.keys(root.appearance.barProfiles || {}).sort().map(name => ({
                label: name.charAt(0).toUpperCase() + name.slice(1),
                value: name
            }))
            value: root.displaySettings.barProfile
            onChosen: profile => root.monitors.setDisplaySetting(root.monitorDescription, "barProfile", profile)
        }
    }
}
