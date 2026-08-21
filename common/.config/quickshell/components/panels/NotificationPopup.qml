import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Effects
import "../../config" as Config

PanelWindow {
    id: root

    required property var notificationServer
    required property var appearance

    screen: Quickshell.screens.values.length > 0 ? Quickshell.screens.values[0] : null
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    implicitWidth: 404
    implicitHeight: notificationList.implicitHeight + 24

    WlrLayershell.namespace: "ndro-shell-notifications"
    mask: Region {
        item: notificationList
    }

    anchors {
        top: true
        left: true
    }

    margins {
        top: root.appearance.barHeight + root.appearance.spacing
        left: screen ? (screen.width - root.implicitWidth) / 2 : 0
    }

    Config.Theme {
        id: theme
    }

    Column {
        id: notificationList

        x: 12
        y: 12
        width: root.implicitWidth - 24
        spacing: 8

        Repeater {
            model: root.notificationServer.trackedNotifications

            delegate: Rectangle {
                id: notificationCard

                required property var modelData
                property real reveal: 0

                width: parent.width
                height: content.implicitHeight + 28
                radius: root.appearance.radius
                color: theme.surface
                border.color: theme.border
                border.width: 1
                opacity: reveal

                layer.enabled: true
                layer.effect: MultiEffect {
                    shadowEnabled: true
                    shadowColor: "#73000000"
                    shadowBlur: 0.65
                    shadowVerticalOffset: 6
                }

                transform: Translate {
                    y: -16 * (1 - notificationCard.reveal)
                }

                Component.onCompleted: reveal = 1

                Behavior on reveal {
                    NumberAnimation {
                        duration: 180
                        easing.type: Easing.OutCubic
                    }
                }

                Timer {
                    interval: notificationCard.modelData.expireTimeout > 0
                        ? notificationCard.modelData.expireTimeout : 5000
                    running: true
                    onTriggered: notificationCard.modelData.dismiss()
                }

                Row {
                    id: content

                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 12

                    Rectangle {
                        width: 76
                        height: 76
                        radius: root.appearance.radius
                        color: theme.accent

                        Image {
                            anchors.fill: parent
                            anchors.margins: 2
                            source: notificationCard.modelData.image !== ""
                                ? notificationCard.modelData.image
                                : notificationCard.modelData.appIcon !== ""
                                    ? Quickshell.iconPath(notificationCard.modelData.appIcon, true) : ""
                            fillMode: Image.PreserveAspectCrop
                        }

                        Text {
                            anchors.centerIn: parent
                            visible: parent.children[0].status !== Image.Ready
                            text: "󰂚"
                            color: theme.background
                            font.pixelSize: 20
                            font.bold: true
                        }
                    }

                    Column {
                        width: parent.width - 116
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 3

                        Text {
                            width: parent.width
                            text: notificationCard.modelData.appName
                            color: theme.textMuted
                            elide: Text.ElideRight
                            font.pixelSize: root.appearance.textSize - 2
                            font.bold: true
                        }

                        Text {
                            width: parent.width
                            text: notificationCard.modelData.summary
                            color: theme.text
                            elide: Text.ElideRight
                            font.pixelSize: root.appearance.textSize + 1
                            font.bold: true
                        }

                        Text {
                            width: parent.width
                            visible: text !== ""
                            text: notificationCard.modelData.body
                            color: theme.textMuted
                            textFormat: Text.PlainText
                            wrapMode: Text.WordWrap
                            maximumLineCount: 3
                            elide: Text.ElideRight
                            font.pixelSize: root.appearance.textSize - 1
                            font.bold: true
                        }
                    }
                }

                Rectangle {
                    anchors.top: parent.top
                    anchors.right: parent.right
                    anchors.margins: 10
                    width: 24
                    height: 24
                    radius: root.appearance.radius
                    color: closeHover.hovered ? theme.surfaceHover : theme.backgroundSecondary

                    Behavior on color {
                        ColorAnimation { duration: 140 }
                    }

                    HoverHandler {
                        id: closeHover
                    }

                    Text {
                        anchors.centerIn: parent
                        text: "󰅖"
                        color: theme.textMuted
                        font.pixelSize: 15
                        font.bold: true
                    }

                    TapHandler {
                        onTapped: notificationCard.modelData.dismiss()
                    }
                }

                TapHandler {
                    onTapped: notificationCard.modelData.dismiss()
                }
            }
        }
    }
}
