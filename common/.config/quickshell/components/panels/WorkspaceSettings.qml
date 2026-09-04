import Quickshell.Hyprland
import QtQuick
import "../../config" as Config

Column {
    id: root

    property var appearance
    property var monitors
    readonly property var connectedMonitors: Hyprland.monitors.values

    width: parent ? parent.width : 0
    spacing: 12

    Config.Theme {
        id: theme
    }

    Repeater {
        model: root.connectedMonitors

        delegate: Column {
            required property var modelData
            readonly property string monitorDescription: modelData.description

            width: parent.width
            spacing: 5
            visible: monitorDescription !== ""

            Text {
                width: parent.width
                text: monitorDescription.toUpperCase()
                color: theme.textMuted
                elide: Text.ElideRight
                font.pixelSize: 11
                font.bold: true
            }

            Row {
                width: parent.width
                spacing: 8

                SettingsInput {
                    width: (parent.width - parent.spacing) / 2
                    appearance: root.appearance
                    text: String(root.monitors.rangeFor(monitorDescription).from)
                    validator: IntValidator { bottom: 1 }
                    onEditingFinished: root.monitors.setRangeStart(monitorDescription, Number(text))
                }

                SettingsInput {
                    width: (parent.width - parent.spacing) / 2
                    appearance: root.appearance
                    text: String(root.monitors.rangeFor(monitorDescription).to)
                    validator: IntValidator { bottom: 1 }
                    onEditingFinished: root.monitors.setRangeEnd(monitorDescription, Number(text))
                }
            }

            Repeater {
                model: [
                    { label: "BAR", propertyName: "barVisible" },
                    { label: "BACKGROUND CLOCK", propertyName: "backgroundClockVisible" }
                ]

                delegate: Rectangle {
                    id: settingToggle

                    required property var modelData

                    width: parent.width
                    height: 38
                    radius: root.appearance.radius
                    color: toggleHover.hovered ? theme.surfaceHover : theme.backgroundSecondary

                    HoverHandler {
                        id: toggleHover
                    }

                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        text: settingToggle.modelData.label
                        color: theme.text
                        font.pixelSize: root.appearance.textSize - 1
                        font.bold: true
                    }

                    Rectangle {
                        anchors.right: parent.right
                        anchors.rightMargin: 10
                        anchors.verticalCenter: parent.verticalCenter
                        width: 42
                        height: 24
                        radius: root.appearance.radius
                        color: root.monitors.displaySettingsFor(monitorDescription)[settingToggle.modelData.propertyName]
                            ? theme.accent : theme.surface

                        Rectangle {
                            x: root.monitors.displaySettingsFor(monitorDescription)[settingToggle.modelData.propertyName]
                                ? parent.width - width - 3 : 3
                            anchors.verticalCenter: parent.verticalCenter
                            width: 18
                            height: 18
                            radius: 9
                            color: theme.text

                            Behavior on x {
                                NumberAnimation {
                                    duration: 160
                                    easing.type: Easing.OutCubic
                                }
                            }
                        }
                    }

                    TapHandler {
                        onTapped: root.monitors.setDisplaySetting(
                            monitorDescription,
                            settingToggle.modelData.propertyName,
                            !root.monitors.displaySettingsFor(monitorDescription)[settingToggle.modelData.propertyName]
                        )
                    }
                }
            }
        }
    }
}
