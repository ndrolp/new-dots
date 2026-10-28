import Quickshell
import QtQuick
import "../../config" as Config
import "." as Panels

// The system monitor's popup: CPU, memory, temperature, disk, network and GPU.
BarPopup {
    id: root

    required property var systemMonitor

    popup: "system"
    edge: "left"
    implicitWidth: 360

    Config.Theme {
        id: theme
    }

    Column {
        width: parent.width
        spacing: 6

        PopupHeader {
            appearance: root.appearance
            title: "System resources"

            PopupLabel {
                appearance: root.appearance
                text: "Load " + root.systemMonitor.loadAverage
            }
        }

        Repeater {
            model: [
                { label: "󰍛  CPU", value: Math.round(root.systemMonitor.cpuUsage) + "%" },
                {
                    label: "󰘚  Memory",
                    value: root.systemMonitor.memoryUsedGiB.toFixed(1)
                        + " / " + root.systemMonitor.memoryTotalGiB.toFixed(1) + " GiB"
                        + " · " + Math.round(root.systemMonitor.memoryUsage) + "%"
                },
                {
                    label: "  Temperature",
                    value: root.systemMonitor.temperature > 0
                        ? Math.round(root.systemMonitor.temperature) + "°C" : "--"
                },
                {
                    label: "󰋊  Disk",
                    value: root.systemMonitor.diskTotalGiB > 0
                        ? root.systemMonitor.diskUsedGiB.toFixed(0) + " / "
                            + root.systemMonitor.diskTotalGiB.toFixed(0) + " GiB"
                        : "--"
                },
                {
                    label: "󰕒  Network",
                    value: "↓ " + root.systemMonitor.formatRate(root.systemMonitor.networkDownloadRate)
                        + "  ↑ " + root.systemMonitor.formatRate(root.systemMonitor.networkUploadRate)
                },
                {
                    label: "󰢮  GPU",
                    value: root.systemMonitor.gpuUsage >= 0
                        ? Math.round(root.systemMonitor.gpuUsage) + "% · "
                            + Math.round(root.systemMonitor.gpuTemperature) + "°C"
                        : "Unavailable"
                }
            ]

            delegate: Item {
                required property var modelData

                width: parent.width
                height: 22

                Panels.Text {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    text: modelData.label
                    color: theme.textMuted
                    font.pixelSize: root.appearance.textSize - 1
                }

                Panels.Text {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    text: modelData.value
                    color: theme.text
                    font.pixelSize: root.appearance.textSize - 1
                }
            }
        }
    }
}
