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

        Panels.SettingsNumber {
            width: parent.width
            appearance: root.appearance
            label: "Blur strength"
            from: WindowAppearance.settings.blur_size.min
            to: WindowAppearance.settings.blur_size.max
            value: root.values.blur_size
            onEdited: number => root.set("blur_size", number)
        }

        Panels.SettingsHint {
            x: 12
            width: parent.width - 24
            appearance: root.appearance
            text: "Also used behind the bar and popups."
        }
    }
}
