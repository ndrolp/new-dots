import QtQuick
import "." as Panels
import "../../config/BarProfileModel.js" as BarProfileModel

// The Bar section's Style, Bar and Groups cards for the edited bar profile:
// the Bar style and Bar position as choices, then the bar's own sizes after a
// density preset, then its groups'. Numbers and switches sit two per line.
Column {
    id: root

    required property var appearance

    width: parent ? parent.width : 0
    spacing: 12

    // A choice's options from the profile values it offers, each labelled
    // by its value with a capital letter: "top" is offered as "Top".
    function choiceOptions(values) {
        return values.map(value => ({
            label: value.charAt(0).toUpperCase() + value.slice(1),
            value: value
        }));
    }

    Panels.SettingsCard {
        appearance: root.appearance
        title: "Style"

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
    }

    Panels.SettingsCard {
        appearance: root.appearance
        title: "Bar"

        // Density presets fill in the sizes in one go; they are a pending
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

        // The edge margin is still stored as the transparent bar margin.
        Panels.BarSettingsGrid {
            appearance: root.appearance
            settings: [
                { label: "Bar thickness", from: 24, to: 56, propertyName: "barHeight" },
                { label: "Bar opacity", from: 20, to: 100, propertyName: "barOpacity" },
                { label: "Corner radius", from: 0, to: 24, propertyName: "radius" },
                { label: "Horizontal padding", from: 0, to: 48, propertyName: "horizontalPadding" },
                { label: "Vertical padding", from: 0, to: 16, propertyName: "elementVerticalPadding" },
                { label: "Bar border", propertyName: "barBorder" },
                { label: "Edge margin", from: 0, to: 32, propertyName: "transparentBarTopMargin" }
            ]
        }
    }

    Panels.SettingsCard {
        appearance: root.appearance
        title: "Groups"

        Panels.BarSettingsGrid {
            appearance: root.appearance
            settings: [
                { label: "Group radius", from: 0, to: 32, propertyName: "groupRadius" },
                { label: "Group horizontal padding", from: 0, to: 24, propertyName: "groupHorizontalPadding" },
                { label: "Group vertical padding", from: 0, to: 16, propertyName: "groupVerticalPadding" },
                { label: "Group border", propertyName: "groupBorder" }
            ]
        }
    }
}
