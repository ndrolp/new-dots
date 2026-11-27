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
}
