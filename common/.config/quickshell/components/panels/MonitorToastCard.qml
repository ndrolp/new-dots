import QtQuick
import "../../config" as Config
import "." as Panels

// The toast for an unknown combination: what the quick switch offers, and Arrange… for Displays.
// Answering only asks: modules/MonitorToast.qml does it. Ignoring it saves nothing.
Rectangle {
    id: card

    required property var appearance
    // What QuickSwitch.choices gives.
    property var choices: []
    signal chosen(var choice)
    signal arrangeAsked()
    signal dismissAsked()

    implicitWidth: 380
    implicitHeight: content.implicitHeight + 32
    width: implicitWidth
    height: implicitHeight
    radius: appearance.radius
    color: theme.surface
    border.color: theme.border
    border.width: 1

    Config.Theme {
        id: theme
    }

    Column {
        id: content

        anchors.centerIn: parent
        width: parent.width - 32
        spacing: 10

        Panels.Text {
            width: parent.width
            text: "New monitors connected"
            color: theme.text
            font.pixelSize: card.appearance.textSize + 1
        }

        Panels.SettingsHint {
            width: parent.width
            appearance: card.appearance
            text: "They're extended for now. Nothing is remembered unless you choose or change something."
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
}
