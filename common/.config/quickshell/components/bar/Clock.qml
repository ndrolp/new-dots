import Quickshell
import QtQuick

// The time beside its icon, with the hours above the minutes on a side bar.
IconValue {
    id: root

    property color color: "white"

    icon: "󰥔"
    iconColor: color
    value: Qt.formatTime(clock.date, "HH:mm")

    SystemClock {
        id: clock
        // Seconds even though it shows minutes: timers stand still during suspend,
        // so a minute tick would leave the old time up for as long as a minute after
        // resuming.
        precision: SystemClock.Seconds
    }
}
