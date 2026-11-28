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

    // A slider for one setting, by its key, in that setting's range. `factor`
    // shows it scaled (100 for a fraction shown as a percentage).
    component WindowSetting: Panels.SettingsNumber {
        required property string key
        property real factor: 1

        width: parent.width
        appearance: root.appearance
        from: Math.round(WindowAppearance.settings[key].min * factor)
        to: Math.round(WindowAppearance.settings[key].max * factor)
        value: Math.round(root.values[key] * factor)
        onEdited: number => root.set(key, number / factor)
    }

    width: parent ? parent.width : 0
    spacing: 12

    // Above the settings' cards, so a new card only goes below them.
    Panels.SettingsCard {
        appearance: root.appearance

        // In the section, not a toast: what was set is saved and Hyprland
        // reads it when it starts. It goes once an apply works again.
        Panels.SettingsHint {
            width: parent.width
            appearance: root.appearance
            visible: !!root.windowAppearance && root.windowAppearance.applyFailed
            text: "Couldn't apply to Hyprland; it will apply on next start."
        }

        // Asks nothing: the service removes the saved file and applies at once.
        Panels.SettingsButton {
            anchors.right: parent.right
            appearance: root.appearance
            label: "Reset to defaults"
            onActivated: {
                if (root.windowAppearance)
                    root.windowAppearance.reset();
            }
        }
    }

    Panels.SettingsCard {
        appearance: root.appearance
        title: "Gaps"

        WindowSetting {
            label: "Inner gaps"
            key: "gaps_in"
        }

        WindowSetting {
            label: "Outer gaps"
            key: "gaps_out"
        }
    }

    Panels.SettingsCard {
        appearance: root.appearance
        title: "Borders"

        WindowSetting {
            label: "Border size"
            key: "border_size"
        }

        WindowSetting {
            label: "Corner radius"
            key: "rounding"
        }
    }

    // Opacity is saved as Hyprland takes it (0–1) and shown as a percentage.
    Panels.SettingsCard {
        appearance: root.appearance
        title: "Opacity and shadows"

        WindowSetting {
            label: "Focused window opacity"
            key: "active_opacity"
            factor: 100
        }

        WindowSetting {
            label: "Unfocused window opacity"
            key: "inactive_opacity"
            factor: 100
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

    // Window blur only affects windows (a window rule); the strength is
    // Hyprland's blur size, so the shell's blur uses it too.
    Panels.SettingsCard {
        appearance: root.appearance
        title: "Blur"

        Panels.SettingsSwitchRow {
            width: parent.width
            appearance: root.appearance
            label: "Window blur"
            checked: root.values.window_blur
            onToggled: root.set("window_blur", !root.values.window_blur)
        }

        WindowSetting {
            label: "Blur strength"
            key: "blur_size"
        }

        Panels.SettingsHint {
            width: parent.width
            appearance: root.appearance
            text: "Also used behind the bar and popups."
        }
    }
}
