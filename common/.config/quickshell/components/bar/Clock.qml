import Quickshell
import QtQuick
import "ClockText.js" as ClockText

// The time beside its icon, with the hours above the minutes on a side bar.
// In a capsule whose row shows its expanded view the date comes before the
// time, dimmer (ClockText.clockText).
IconValue {
    id: root

    property color color: "white"
    readonly property var shown: ClockText.clockText(appearance, clock.date)

    icon: "󰥔"
    iconColor: color
    iconSize: appearance.iconSize
    valueSize: appearance.textSize
    value: shown.time
    lead: shown.date
    leadColor: Qt.rgba(color.r, color.g, color.b, 0.6)

    SystemClock {
        id: clock
        // Seconds even though it shows minutes: timers stand still during suspend,
        // so a minute tick would leave the old time up for as long as a minute after
        // resuming.
        precision: SystemClock.Seconds
    }
}
