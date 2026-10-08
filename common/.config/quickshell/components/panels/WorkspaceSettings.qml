import Quickshell.Hyprland
import Quickshell
import QtQuick
import "../../config" as Config

Column {
    id: root

    property var appearance
    property var monitors
    width: parent ? parent.width : 0
    spacing: 12

    function monitorDescriptionForScreen(screen) {
        const monitor = Hyprland.monitorFor(screen);
        return monitor !== null && monitor.description !== "" ? monitor.description : screen.name;
    }

    Config.Theme {
        id: theme
    }

    Repeater {
        model: Quickshell.screens

        delegate: Column {
            required property var modelData
            readonly property string monitorDescription: root.monitorDescriptionForScreen(modelData)

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

                Rectangle {
                    width: parent.width
                    height: 38
                    radius: root.appearance.radius
                    color: profileHover.hovered ? theme.surfaceHover : theme.backgroundSecondary

                    HoverHandler {
                        id: profileHover
                    }

                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        text: "BAR PROFILE"
                        color: theme.text
                        font.pixelSize: root.appearance.textSize - 1
                        font.bold: true
                    }

                    ComboBox {
                        id: profileSelector

                        anchors.right: parent.right
                        anchors.rightMargin: 6
                        anchors.verticalCenter: parent.verticalCenter
                        width: 144
                        height: 30
                        textRole: "label"
                        model: [
                            { label: "Use active", value: "" },
                            { label: "Minimal", value: "minimal" },
                            { label: "Work", value: "work" },
                            { label: "Media", value: "media" },
                            { label: "Presentation", value: "presentation" }
                        ]
                        currentIndex: {
                            const profile = root.monitors.displaySettingsFor(monitorDescription).barProfile;
                            for (let index = 0; index < model.length; index++) {
                                if (model[index].value === profile)
                                    return index;
                            }

                            return 0;
                        }

                        contentItem: Text {
                            leftPadding: 8
                            verticalAlignment: Text.AlignVCenter
                            text: profileSelector.displayText
                            color: theme.accent
                            font.pixelSize: root.appearance.textSize - 2
                            font.bold: true
                        }

                        indicator: Item {}

                        background: Rectangle {
                            radius: root.appearance.radius
                            color: theme.surface
                        }

                        onActivated: root.monitors.setDisplaySetting(
                            monitorDescription, "barProfile", model[index].value
                        )
                    }
                }
            }
        }
    }
}
