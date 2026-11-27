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
