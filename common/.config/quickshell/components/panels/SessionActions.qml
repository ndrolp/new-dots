import QtQuick
import "." as Panels

// The Session section's actions card: quiet buttons, two per line, each with
// what it does underneath. A button only asks for its command: the section
// runs it.
Panels.SettingsCard {
    id: root

    signal requested(var command)

    title: "Actions"

    Panels.SettingsGrid {
        Repeater {
            model: [
                {
                    icon: "󰌾",
                    label: "Lock now",
                    description: "Lock this session with Hyprlock.",
                    command: ["loginctl", "lock-session"]
                },
                {
                    icon: "󰍹",
                    label: "Turn displays off",
                    description: "Turn displays off until the next input.",
                    command: ["hyprctl", "dispatch", "dpms", "off"]
                },
                {
                    icon: "󰤄",
                    label: "Suspend",
                    description: "Lock and suspend the computer.",
                    command: ["systemctl", "suspend"]
                }
            ]

            // Labelled by the action's name, so the settings search finds it.
            delegate: Column {
                id: action

                required property var modelData
                readonly property string label: modelData.label

                width: parent.cellWidth
                spacing: 2

                Panels.SettingsButton {
                    appearance: root.appearance
                    label: action.modelData.icon + "  " + action.modelData.label
                    onActivated: root.requested(action.modelData.command)
                }

                Panels.SettingsHint {
                    width: parent.width
                    leftPadding: 14
                    appearance: root.appearance
                    text: action.modelData.description
                }
            }
        }
    }
}
