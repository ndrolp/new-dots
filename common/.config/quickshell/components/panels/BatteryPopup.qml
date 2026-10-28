import Quickshell
import Quickshell.Services.UPower
import QtQuick
import "../../config" as Config
import "." as Panels
import "../StatusText.js" as StatusText

// The battery popup: the charge, its state, health, power draw and time left.
BarPopup {
    id: root

    required property var systemMonitor

    readonly property var battery: UPower.displayDevice
    readonly property bool charging: !!battery && battery.state === UPowerDeviceState.Charging

    popup: "battery"
    implicitWidth: 340

    Config.Theme {
        id: theme
    }

    Column {
        width: parent.width
        spacing: 10

        PopupHeader {
            appearance: root.appearance
            icon: StatusText.batteryIcon(root.battery, UPowerDeviceState)
            iconColor: root.charging ? theme.yellow : theme.textMuted
            title: StatusText.batteryStateLabel(root.battery, UPowerDeviceState)
            subtitle: root.battery
                ? Math.round(root.battery.percentage * 100) + "%"
                : "No battery detected"
        }

        PopupProgress {
            appearance: root.appearance
            width: parent.width
            fraction: root.battery ? root.battery.percentage : 0
            fillColor: root.charging ? theme.yellow : theme.green
        }

        Row {
            width: parent.width
            spacing: 8

            Repeater {
                model: [
                    {
                        label: "Health",
                        value: root.systemMonitor.batteryHealth !== ""
                            ? root.systemMonitor.batteryHealth
                            : root.battery && root.battery.healthSupported
                                ? Math.round(root.battery.healthPercentage * 100) + "%"
                                : "Unavailable"
                    },
                    {
                        label: "Power draw",
                        value: root.battery
                            ? Math.abs(root.battery.changeRate).toFixed(1) + " W"
                            : "Unavailable"
                    },
                    {
                        label: root.charging ? "Time to full" : "Time left",
                        value: root.charging
                            ? (root.systemMonitor.batteryTimeToFull || "Calculating")
                            : (root.systemMonitor.batteryTimeToEmpty || "Calculating")
                    }
                ]

                delegate: Column {
                    required property var modelData

                    width: (parent.width - parent.spacing * 2) / 3
                    spacing: 2

                    PopupLabel {
                        appearance: root.appearance
                        width: parent.width
                        text: modelData.label
                    }

                    Panels.Text {
                        width: parent.width
                        text: modelData.value
                        color: theme.text
                        elide: Text.ElideRight
                        font.pixelSize: root.appearance.textSize - 1
                    }
                }
            }
        }
    }
}
