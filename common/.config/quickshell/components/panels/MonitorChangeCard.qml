import QtQuick
import "../../config" as Config
import "." as Panels

// The Keep or Revert question after any change of monitors, wherever it was made. Answering only
// asks: the service does it. modules/MonitorChange.qml shows this on every screen that still works.
Rectangle {
    id: card

    required property var appearance
    property int secondsLeft: 0
    signal keepAsked()
    signal revertAsked()

    implicitWidth: 340
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
            text: "Keep these display settings?"
            color: theme.text
            font.pixelSize: card.appearance.textSize + 1
        }

        Panels.SettingsHint {
            width: parent.width
            appearance: card.appearance
            text: "Reverting in " + card.secondsLeft + (card.secondsLeft === 1 ? " second" : " seconds")
        }

        Row {
            anchors.right: parent.right
            spacing: 8

            Panels.SettingsButton {
                appearance: card.appearance
                label: "Revert"
                onActivated: card.revertAsked()
            }

            Panels.SettingsButton {
                appearance: card.appearance
                label: "Keep"
                labelColor: theme.accent
                onActivated: card.keepAsked()
            }
        }
    }
}
