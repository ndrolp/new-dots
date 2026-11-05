import Quickshell
import QtQuick

Row {
    id: root

    property color color: "white"

    spacing: 6

    SystemClock {
        id: clock
        // Seconds even though it shows minutes: timers stand still during suspend,
        // so a minute tick would leave the old time up for as long as a minute after
        // resuming.
        precision: SystemClock.Seconds
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
