import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import QtQuick
import QtQuick.Effects
import "../../config" as Config

Variants {
    id: root

    required property var appearance
    required property var monitors

    model: Quickshell.screens

    delegate: PanelWindow {
        id: clockWindow

        required property var modelData

        screen: modelData
        readonly property var hyprlandMonitor: Hyprland.monitorFor(modelData)
        readonly property string monitorDescription: hyprlandMonitor !== null
            && hyprlandMonitor.description !== "" ? hyprlandMonitor.description : modelData.name
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.namespace: "ndro-shell-background-clock"
        WlrLayershell.layer: WlrLayer.Bottom

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        mask: Region {}

        Config.Theme {
            id: theme
        }

        property date currentTime: new Date()
        readonly property int monthStartDay: new Date(
            currentTime.getFullYear(), currentTime.getMonth(), 1
        ).getDay()
        readonly property int daysInMonth: new Date(
            currentTime.getFullYear(), currentTime.getMonth() + 1, 0
        ).getDate()

        Timer {
            interval: 1000
            running: clockWindow.visible
            repeat: true
            triggeredOnStart: true
            onTriggered: clockWindow.currentTime = new Date()
        }

        visible: root.appearance.backgroundClockEnabled
            && root.monitors.backgroundClockVisible(monitorDescription)

        Column {
            id: clockContent

            x: {
                const position = root.appearance.backgroundClockPosition;
                if (position.endsWith("left"))
                    return 48;
                if (position.endsWith("right"))
                    return parent.width - width - 48;
                return (parent.width - width) / 2;
            }
            y: {
                const position = root.appearance.backgroundClockPosition;
                if (position.startsWith("top"))
                    return 82;
                if (position.startsWith("bottom"))
                    return parent.height - height - 56;
                return (parent.height - height) / 2;
            }
            spacing: root.appearance.backgroundClockCalendarEnabled ? 10 : 4
            opacity: root.appearance.backgroundClockOpacity / 100

            layer.enabled: true
            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowColor: "#70000000"
                shadowBlur: 0.35
                shadowHorizontalOffset: 2
                shadowVerticalOffset: 3
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Qt.formatTime(clockWindow.currentTime, "HH:mm")
                color: theme.text
                font.family: theme.fontFamily
                font.pixelSize: root.appearance.backgroundClockSize
                font.bold: true
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: {
                    switch (root.appearance.backgroundClockDateFormat) {
                    case "short":
                        return Qt.formatDate(clockWindow.currentTime, "ddd, MMM d");
                    case "numeric":
                        return Qt.formatDate(clockWindow.currentTime, "yyyy-MM-dd");
                    case "none":
                        return "";
                    default:
                        return Qt.formatDate(clockWindow.currentTime, "dddd, MMMM d");
                    }
                }
                visible: text !== ""
                color: theme.textMuted
                font.family: theme.fontFamily
                font.pixelSize: root.appearance.textSize + 3
                font.bold: true
            }

            Column {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 5
                visible: root.appearance.backgroundClockCalendarEnabled

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Qt.formatDate(clockWindow.currentTime, "MMMM yyyy").toUpperCase()
                    color: theme.text
                    font.family: theme.fontFamily
                    font.pixelSize: root.appearance.textSize
                    font.bold: true
                }

                Grid {
                    anchors.horizontalCenter: parent.horizontalCenter
                    columns: 7
                    columnSpacing: 8
                    rowSpacing: 5

                    Repeater {
                        model: ["S", "M", "T", "W", "T", "F", "S"]

                        delegate: Text {
                            required property var modelData

                            width: 18
                            horizontalAlignment: Text.AlignHCenter
                            text: modelData
                            color: theme.textDisabled
                            font.family: theme.fontFamily
                            font.pixelSize: root.appearance.textSize - 3
                            font.bold: true
                        }
                    }

                    Repeater {
                        model: 42

                        delegate: Text {
                            required property int index

                            readonly property int day: index - clockWindow.monthStartDay + 1
                            readonly property bool valid: day >= 1 && day <= clockWindow.daysInMonth
                            readonly property bool today: valid
                                && day === clockWindow.currentTime.getDate()

                            width: 18
                            horizontalAlignment: Text.AlignHCenter
                            text: valid ? day : ""
                            color: today ? theme.accent : theme.textMuted
                            font.family: theme.fontFamily
                            font.pixelSize: root.appearance.textSize - 3
                            font.bold: today
                        }
                    }
                }
            }
        }
    }
}
