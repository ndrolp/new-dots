import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower
import QtQuick

// Sends a critical notification once the battery drops to 15% while
// discharging, and again only after it has been above that.
Scope {
    id: root

    property bool notificationSent: false

    Process {
        id: lowBatteryNotification
    }

    Timer {
        interval: 60000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            const battery = UPower.displayDevice;
            const discharging = battery
                && battery.state === UPowerDeviceState.Discharging;
            const critical = discharging && battery.percentage <= 0.15;

            if (critical && !root.notificationSent) {
                lowBatteryNotification.command = [
                    "notify-send", "-u", "critical", "-i", "battery-caution",
                    "Battery low", Math.round(battery.percentage * 100) + "% remaining"
                ];
                lowBatteryNotification.running = true;
                root.notificationSent = true;
            } else if (!critical) {
                root.notificationSent = false;
            }
        }
    }
}
