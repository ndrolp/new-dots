import QtQuick
import "../../config" as Config

// A text button: a row with a centered label.
PopupRow {
    id: button

    property string label: ""
    property color labelColor: theme.text
    property real labelSize: appearance.textSize - 1
    signal activated()

    height: 30

    Config.Theme {
        id: theme
    }

    Text {
        anchors.centerIn: parent
        text: button.label
        color: button.labelColor
        font.pixelSize: button.labelSize
    }

    TapHandler {
        enabled: button.interactive
        onTapped: button.activated()
    }
}
