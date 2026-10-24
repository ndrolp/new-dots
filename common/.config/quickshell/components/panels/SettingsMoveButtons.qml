import QtQuick
import "." as Panels

// Moving an entry up or down its list: a pair of quiet arrow buttons. At an
// end of the list the arrow past it is disabled. A press only asks to move:
// whoever owns the list reorders it.
Row {
    id: buttons

    required property var appearance
    property bool canMoveUp: true
    property bool canMoveDown: true
    signal movedUp()
    signal movedDown()

    Panels.SettingsButton {
        anchors.verticalCenter: parent.verticalCenter
        width: 32
        appearance: buttons.appearance
        label: "󰁝"
        enabled: buttons.canMoveUp
        onActivated: buttons.movedUp()
    }

    Panels.SettingsButton {
        anchors.verticalCenter: parent.verticalCenter
        width: 32
        appearance: buttons.appearance
        label: "󰁅"
        enabled: buttons.canMoveDown
        onActivated: buttons.movedDown()
    }
}
