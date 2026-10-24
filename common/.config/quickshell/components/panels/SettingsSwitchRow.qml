import QtQuick
import "../../config" as Config
import "." as Panels

// An on/off setting: a row that stays transparent until hovered, its label on
// the left and a switch on the right. A tap anywhere on the row only asks to
// toggle: whoever owns the setting flips `checked`.
Rectangle {
    id: row

    required property var appearance
    property string label: ""
    property bool checked: false
    readonly property alias switchItem: rowSwitch
    signal toggled()

    height: 40
    radius: appearance.radius
    color: rowHover.hovered ? theme.surfaceHover : "transparent"

    Behavior on color {
        ColorAnimation { duration: 140 }
    }

    Config.Theme {
        id: theme
    }

    HoverHandler {
        id: rowHover
    }

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
        checked: row.checked
    }

    TapHandler {
        onTapped: row.toggled()
    }
}
