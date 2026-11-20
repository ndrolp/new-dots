import QtQuick
import "." as Panels
import "../../config/BarProfileModel.js" as BarProfileModel

// The Bar section's sizes and style for the edited bar profile: a density
// preset, the sizes as number settings, the Bar position and the Bar style as
// choices, and the style's switches as rows, two per line.
Column {
    id: root

    required property var appearance

    width: parent ? parent.width : 0
    spacing: 14

    // A choice's options from the profile values it offers, each labelled
    // by its value with a capital letter: "top" is offered as "Top".
    function choiceOptions(values) {
        return values.map(value => ({
            label: value.charAt(0).toUpperCase() + value.slice(1),
            value: value
        }));
    }

    Panels.SettingsHeading {
        appearance: root.appearance
        text: "Size & spacing"
        topPadding: 4
    }

    // Density presets fill in the sizes below in one go; they are a pending
    // change like any other and the preset itself is not stored.
    Panels.SettingsField {
        width: parent.width
        appearance: root.appearance
        label: "Density preset"

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
                { label: "Bar thickness", from: 24, to: 56, propertyName: "barHeight" },
                { label: "Bar opacity", from: 20, to: 100, propertyName: "barOpacity" },
                { label: "Corner radius", from: 0, to: 24, propertyName: "radius" },
                { label: "Group radius", from: 0, to: 32, propertyName: "groupRadius" },
                { label: "Horizontal padding", from: 0, to: 48, propertyName: "horizontalPadding" },
                { label: "Component spacing", from: 0, to: 24, propertyName: "spacing" },
                { label: "Bar vertical padding", from: 0, to: 16, propertyName: "elementVerticalPadding" },
                { label: "Pill vertical padding", from: 0, to: 8, propertyName: "pillVerticalPadding" },
                { label: "Workspace bar padding", from: 0, to: 10, propertyName: "workspacePadding" },
                { label: "Transparent bar margin", from: 0, to: 32, propertyName: "transparentBarTopMargin" },
                { label: "Capsule vertical padding", from: 0, to: 16, propertyName: "capsuleVerticalPadding" },
                { label: "Group horizontal padding", from: 0, to: 24, propertyName: "groupHorizontalPadding" },
                { label: "Group vertical padding", from: 0, to: 16, propertyName: "groupVerticalPadding" },
                { label: "Icon size", from: 8, to: 32, propertyName: "iconSize" }
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

    Panels.SettingsField {
        width: parent.width
        appearance: root.appearance
        label: "Bar position"

        Panels.SettingsChoice {
            width: Math.min(parent.width, 360)
            appearance: root.appearance
            // Only the positions the bar style can take: a capsule has no side.
            options: root.choiceOptions(BarProfileModel.barPositionsFor(root.appearance.barStyle))
            value: root.appearance.barPosition
            onChosen: position => root.appearance.setBarSetting("barPosition", position)
        }
    }

    Panels.SettingsField {
        width: parent.width
        appearance: root.appearance
        label: "Bar style"

        Panels.SettingsChoice {
            width: Math.min(parent.width, 360)
            appearance: root.appearance
            options: root.choiceOptions(BarProfileModel.barStyles)
            value: root.appearance.barStyle
            onChosen: style => root.appearance.setBarSetting("barStyle", style)
        }
    }

    Panels.SettingsGrid {
        rowSpacing: 4

        Repeater {
            model: [
                { label: "Transparent pills", propertyName: "pillsTransparent" },
                { label: "Bar border", propertyName: "barBorder" },
                { label: "Element border", propertyName: "elementBorder" },
                { label: "Group border", propertyName: "groupBorder" }
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
