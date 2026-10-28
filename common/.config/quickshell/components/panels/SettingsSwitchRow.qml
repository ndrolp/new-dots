import QtQuick
import "." as Panels

// An on/off setting: a settings row with its label on the left and a switch
// on the right. A tap anywhere on the row only asks to toggle: whoever owns
// the setting flips `checked`.
Panels.SettingsRow {
    id: row

    property string label: ""
    property bool checked: false
    readonly property alias switchItem: rowSwitch
    signal toggled()

    height: 40

    Panels.SettingsLabel {
        anchors.left: parent.left
        anchors.leftMargin: 12
        anchors.right: rowSwitch.left
        anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        appearance: row.appearance
        text: row.label
    }

    Panels.SettingsSwitch {
        id: rowSwitch

        anchors.right: parent.right
        anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        appearance: row.appearance
        checked: row.checked
    }

    TapHandler {
        onTapped: row.toggled()
    }
}
