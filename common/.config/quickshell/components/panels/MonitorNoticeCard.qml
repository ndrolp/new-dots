import QtQuick
import "." as Panels

// A failure with the monitors or their saved setups: what happened, for modules/MonitorToast.qml to
// show on the focused monitor beside the unknown combination's toast.
Panels.MonitorCard {
    id: card

    property string message: ""
    signal dismissAsked()

    implicitWidth: 380
    title: "Displays"
    hint: message

    Panels.SettingsButton {
        objectName: "notice Dismiss"
        anchors.right: parent.right
        appearance: card.appearance
        label: "Dismiss"
        onActivated: card.dismissAsked()
    }
}
