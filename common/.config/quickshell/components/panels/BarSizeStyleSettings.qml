import QtQuick
import "." as Panels

Column {
    id: root

    property var appearance

    width: parent ? parent.width : 0
    spacing: 14

    Panels.SettingsHeading {
        appearance: root.appearance
        text: "Size & spacing"
        topPadding: 4
    }

    // Density presets fill in the sizes below in one go; they are a pending
    // change like any other and the preset itself is not stored.
    Column {
        width: parent.width
        spacing: 6

        Panels.SettingsLabel {
            appearance: root.appearance
            text: "Density preset"
        }

        Panels.SettingsChoice {
            width: Math.min(parent.width, 360)
            appearance: root.appearance
            options: [
                { label: "Compact", value: "compact" },
                { label: "Balanced", value: "balanced" },
                { label: "Spacious", value: "spacious" }
            ]
            value: root.appearance.matchingDensityPreset
            onChosen: preset => root.appearance.applyDensityPreset(preset)
        }
    }

    // Paired by meaning, two per line.
    Panels.SettingsGrid {
        Repeater {
            model: [
                { label: "Bar height", from: 24, to: 56, propertyName: "barHeight" },
                { label: "Bar opacity", from: 20, to: 100, propertyName: "barOpacity" },
                { label: "Corner radius", from: 0, to: 24, propertyName: "radius" },
                { label: "Group radius", from: 0, to: 32, propertyName: "groupRadius" },
                { label: "Horizontal padding", from: 0, to: 48, propertyName: "horizontalPadding" },
                { label: "Component spacing", from: 0, to: 24, propertyName: "spacing" },
                { label: "Bar vertical padding", from: 0, to: 16, propertyName: "elementVerticalPadding" },
                { label: "Pill vertical padding", from: 0, to: 8, propertyName: "pillVerticalPadding" },
                { label: "Workspace bar padding", from: 0, to: 10, propertyName: "workspacePadding" },
                { label: "Transparent bar top margin", from: 0, to: 32, propertyName: "transparentBarTopMargin" }
            ]

            delegate: Panels.SettingsNumber {
                required property var modelData

                width: parent.cellWidth
                appearance: root.appearance
                label: modelData.label
                from: modelData.from
                to: modelData.to
                value: root.appearance[modelData.propertyName]
                onEdited: number => root.appearance.setBarSetting(modelData.propertyName, number)
            }
        }
    }

    Panels.SettingsHeading {
        appearance: root.appearance
        text: "Style"
        topPadding: 8
    }

    Panels.SettingsGrid {
        rowSpacing: 4

        Repeater {
            model: [
                { label: "Transparent bar", propertyName: "barTransparent" },
                { label: "Transparent bar border", propertyName: "barTransparentBorder" },
                { label: "Docked bar", propertyName: "transparentBarSlanted" },
                { label: "Transparent pills", propertyName: "pillsTransparent" }
            ]

            delegate: Panels.SettingsSwitchRow {
                required property var modelData

                width: parent.cellWidth
                appearance: root.appearance
                label: modelData.label
                checked: root.appearance[modelData.propertyName]
                onToggled: root.appearance.setBarSetting(modelData.propertyName,
                    !root.appearance[modelData.propertyName])
            }
        }
    }
}
