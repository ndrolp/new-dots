import QtQuick
import "../../config" as Config
import "." as Panels

// The Keep or Revert question after any change of monitors, wherever it was made. Answering only
// asks: the service does it. modules/MonitorChange.qml shows this on every screen that still works.
Panels.MonitorCard {
    id: card

    property int secondsLeft: 0
    signal keepAsked()
    signal revertAsked()

    focus: true
    title: "Keep these display settings?"
    hint: "Reverting in " + secondsLeft + (secondsLeft === 1 ? " second" : " seconds")

    Keys.onReturnPressed: keepAsked()
    Keys.onEnterPressed: keepAsked()
    Keys.onEscapePressed: revertAsked()

    Config.Theme {
        id: theme
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
