import Quickshell
import QtQuick

Row {
    id: root

    property color color: "white"

    spacing: 6

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    Text {
        anchors.verticalCenter: parent.verticalCenter
        text: "󰥔"
        color: root.color
        font.pixelSize: 14
        font.bold: true
    }

    Text {
        anchors.verticalCenter: parent.verticalCenter
        text: Qt.formatTime(clock.date, "HH:mm")
        color: root.color
        font.pixelSize: 14
        font.bold: true
    }
}
