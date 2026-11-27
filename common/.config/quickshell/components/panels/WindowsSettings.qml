import QtQuick
import "." as Panels
import "../../services/WindowAppearance.js" as WindowAppearance

// How Hyprland draws windows (global, not part of any bar profile, the same
// on every monitor). Each change goes to `windowAppearance` (the shell's
// WindowAppearance service), which saves and applies it straight away.
Column {
    id: root

    required property var appearance
    property var windowAppearance

    readonly property var values: windowAppearance ? windowAppearance.values : WindowAppearance.defaults()

    function set(key, value) {
        if (windowAppearance)
            windowAppearance.set(key, value);
    }

    width: parent ? parent.width : 0
    spacing: 12

    Panels.SettingsCard {
        appearance: root.appearance
        title: "Gaps"

        Panels.SettingsNumber {
            width: parent.width
            appearance: root.appearance
            label: "Inner gaps"
            from: WindowAppearance.settings.gaps_in.min
            to: WindowAppearance.settings.gaps_in.max
            value: root.values.gaps_in
            onEdited: number => root.set("gaps_in", number)
        }

        Panels.SettingsNumber {
            width: parent.width
            appearance: root.appearance
            label: "Outer gaps"
            from: WindowAppearance.settings.gaps_out.min
            to: WindowAppearance.settings.gaps_out.max
            value: root.values.gaps_out
            onEdited: number => root.set("gaps_out", number)
        }
    }

    Panels.SettingsCard {
        appearance: root.appearance
        title: "Borders"

        Panels.SettingsNumber {
            width: parent.width
            appearance: root.appearance
            label: "Border size"
            from: WindowAppearance.settings.border_size.min
            to: WindowAppearance.settings.border_size.max
            value: root.values.border_size
            onEdited: number => root.set("border_size", number)
        }

        Panels.SettingsNumber {
            width: parent.width
            appearance: root.appearance
            label: "Corner radius"
            from: WindowAppearance.settings.rounding.min
            to: WindowAppearance.settings.rounding.max
            value: root.values.rounding
            onEdited: number => root.set("rounding", number)
        }
    }

    // Opacity is saved as Hyprland takes it (0–1) and shown as a percentage.
    Panels.SettingsCard {
        appearance: root.appearance
        title: "Opacity and shadows"

        Panels.SettingsNumber {
            width: parent.width
            appearance: root.appearance
            label: "Focused window opacity"
            from: Math.round(WindowAppearance.settings.active_opacity.min * 100)
            to: Math.round(WindowAppearance.settings.active_opacity.max * 100)
            value: Math.round(root.values.active_opacity * 100)
            onEdited: number => root.set("active_opacity", number / 100)
        }

        Panels.SettingsNumber {
            width: parent.width
            appearance: root.appearance
            label: "Unfocused window opacity"
            from: Math.round(WindowAppearance.settings.inactive_opacity.min * 100)
            to: Math.round(WindowAppearance.settings.inactive_opacity.max * 100)
            value: Math.round(root.values.inactive_opacity * 100)
            onEdited: number => root.set("inactive_opacity", number / 100)
        }

        Panels.SettingsHint {
            width: parent.width
            appearance: root.appearance
            text: "Some apps are a little more transparent by their own rule."
        }

        Panels.SettingsSwitchRow {
            width: parent.width
            appearance: root.appearance
            label: "Shadows"
            checked: root.values.shadows
            onToggled: root.set("shadows", !root.values.shadows)
        }
    }
}
