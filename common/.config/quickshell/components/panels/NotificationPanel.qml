import Quickshell
import QtQuick
import QtQuick.Effects
import "../../config" as Config

PopupWindow {
    id: root

    required property var appearance
    required property var notificationServer
    required property var notificationHistory
    property bool open: false
    property var targetWindow
    property real reveal: open ? 1 : 0

    signal closeRequested()

    onVisibleChanged: {
        if (!visible && open)
            closeRequested();
    }

    visible: reveal > 0 && targetWindow !== null
    anchor.window: targetWindow
    anchor.rect.x: targetWindow ? (targetWindow.width - implicitWidth) / 2 : 0
    anchor.rect.y: appearance.barHeight + appearance.spacing
    color: "transparent"
    grabFocus: true
    implicitWidth: 424
    implicitHeight: notificationList.implicitHeight + 48

    Config.Theme {
        id: theme
    }

    function clearNotifications() {
        notificationHistory.clear();
    }

    Behavior on reveal {
        NumberAnimation {
            duration: 200
            easing.type: Easing.OutCubic
        }
    }

    Rectangle {
        anchors.fill: parent
        anchors.margins: 12
        anchors.topMargin: 12 - 16 * (1 - root.reveal)
        radius: root.appearance.radius
        color: theme.surface
        opacity: root.reveal

        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: "#73000000"
            shadowBlur: 0.65
            shadowVerticalOffset: 6
        }

        Column {
            id: notificationList

            anchors.fill: parent
            anchors.margins: 16
            spacing: 8

            Row {
                width: parent.width

                Text {
                    text: "Notifications"
                    color: theme.text
                    font.pixelSize: root.appearance.textSize + 3
                    font.bold: true
                }

                Item {
                    width: parent.width - parent.children[0].implicitWidth - clearButton.width
                    height: 1
                }

                Text {
                    id: clearButton

                    visible: root.notificationHistory.items.length > 0
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Clear all"
                    color: clearHover.hovered ? theme.accent : theme.textMuted
                    font.pixelSize: root.appearance.textSize - 1
                    font.bold: true

                    HoverHandler {
                        id: clearHover
                    }

                    TapHandler {
                        onTapped: root.clearNotifications()
                    }
                }
            }

            Text {
                visible: root.notificationHistory.items.length === 0
                width: parent.width
                height: 64
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                text: "No notifications"
                color: theme.textMuted
                font.pixelSize: root.appearance.textSize
                font.bold: true
            }

            Repeater {
                model: root.notificationHistory.items

                delegate: Rectangle {
                    required property var modelData

                    width: notificationList.width
                    height: 64
                    radius: root.appearance.radius
                    color: notificationHover.hovered ? theme.surfaceHover : theme.backgroundSecondary

                    Behavior on color {
                        ColorAnimation { duration: 140 }
                    }

                    HoverHandler {
                        id: notificationHover
                    }

                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        text: "󰂚"
                        color: theme.accent
                        font.pixelSize: 18
                        font.bold: true
                    }

                    Column {
                        anchors.left: parent.left
                        anchors.leftMargin: 42
                        anchors.right: parent.right
                        anchors.rightMargin: 14
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 2

                        Text {
                            width: parent.width
                            text: modelData.summary || modelData.appName
                            color: theme.text
                            elide: Text.ElideRight
                            font.pixelSize: root.appearance.textSize
                            font.bold: true
                        }

                        Text {
                            width: parent.width
                            visible: text !== ""
                            text: modelData.body
                            color: theme.textMuted
                            textFormat: Text.PlainText
                            elide: Text.ElideRight
                            font.pixelSize: root.appearance.textSize - 2
                            font.bold: true
                        }
                    }

                    TapHandler {
                        onTapped: root.notificationHistory.remove(modelData.id)
                    }
                }
            }
        }
    }
}
