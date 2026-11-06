import QtQuick
import "../../config" as Config
import "." as Panels

// The toast for an unknown combination: what the quick switch offers, and Arrange… for Displays.
// Answering only asks: modules/MonitorToast.qml does it. Ignoring it saves nothing.
Panels.MonitorCard {
    id: card

    // What QuickSwitch.choices gives.
    property var choices: []
    signal chosen(var choice)
    signal arrangeAsked()
    signal dismissAsked()

    implicitWidth: 380
    title: "New monitors connected"
    hint: "They're extended for now. Nothing is remembered unless you choose or change something."

    Config.Theme {
        id: theme
    }

    Flow {
        width: parent.width
        spacing: 4

        Repeater {
            model: card.choices

            delegate: Panels.SettingsButton {
                required property var modelData

                objectName: "toast " + modelData.label
                appearance: card.appearance
                label: modelData.label
                onActivated: card.chosen(modelData)
            }
        }

        Panels.SettingsButton {
            objectName: "toast Arrange…"
            appearance: card.appearance
            label: "Arrange…"
            labelColor: theme.accent
            onActivated: card.arrangeAsked()
        }

        Panels.SettingsButton {
            objectName: "toast Dismiss"
            appearance: card.appearance
            label: "Dismiss"
            onActivated: card.dismissAsked()
        }
    }
}
