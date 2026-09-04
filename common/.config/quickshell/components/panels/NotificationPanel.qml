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
        border.color: theme.border
        border.width: 1

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
                height: 28

                Text {
                    text: "Notifications"
                    color: theme.text
                    font.pixelSize: root.appearance.textSize + 3
                    font.bold: true
                }

                Item {
                    width: parent.width - parent.children[0].implicitWidth
                        - doNotDisturbButton.width - clearButton.width - 12
                    height: 1
                }

                Text {
                    id: doNotDisturbButton

                    anchors.verticalCenter: parent.verticalCenter
                    text: root.appearance.doNotDisturb ? "󰂛  DND on" : "󰂚  DND off"
                    color: doNotDisturbHover.hovered ? theme.accent : root.appearance.doNotDisturb
                        ? theme.accent : theme.textMuted
                    font.pixelSize: root.appearance.textSize - 1
                    font.bold: true

                    HoverHandler {
                        id: doNotDisturbHover
                    }

                    TapHandler {
                        onTapped: root.appearance.doNotDisturb = !root.appearance.doNotDisturb
                    }
                }

                Item {
                    width: 12
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

            Flickable {
                id: notificationScroller

                visible: root.notificationHistory.items.length > 0
                width: parent.width
                height: Math.min(520, notificationGroups.implicitHeight)
                implicitHeight: height
                contentWidth: width
                contentHeight: notificationGroups.implicitHeight
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                Column {
                    id: notificationGroups

                    width: notificationScroller.width
                    spacing: 12

                    Repeater {
                        model: root.notificationHistory.groups

                        delegate: Column {
                            required property var modelData

                            width: notificationGroups.width
                            spacing: 6

                            Text {
                                width: parent.width
                                text: modelData.appName
                                color: theme.textMuted
                                elide: Text.ElideRight
                                font.pixelSize: root.appearance.textSize - 2
                                font.bold: true
                            }

                            Repeater {
                                model: parent.modelData.items

                                delegate: Rectangle {
                                    id: notificationEntry

                                    required property var modelData

                                    width: notificationGroups.width
                                    readonly property var actions: modelData.notification
                                        ? modelData.notification.actions : []
                                    height: 64 + (actions.length > 0 ? 36 : 0)
                                    radius: root.appearance.radius
                                    color: notificationHover.hovered
                                        ? theme.surfaceHover : theme.backgroundSecondary

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

                                    Rectangle {
                                        anchors.right: parent.right
                                        anchors.rightMargin: 10
                                        anchors.top: parent.top
                                        anchors.topMargin: 8
                                        visible: modelData.count > 1
                                        width: 24
                                        height: 20
                                        radius: 10
                                        color: theme.accent

                                        Text {
                                            anchors.centerIn: parent
                                            text: modelData.count
                                            color: theme.background
                                            font.pixelSize: root.appearance.textSize - 3
                                            font.bold: true
                                        }
                                    }

                                    Column {
                                        anchors.left: parent.left
                                        anchors.leftMargin: 42
                                        anchors.right: parent.right
                                        anchors.rightMargin: modelData.count > 1 ? 42 : 14
                                        anchors.top: parent.top
                                        anchors.topMargin: 11
                                        spacing: 2

                                        Text {
                                            width: parent.width
                                            text: modelData.summary || "Notification"
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

                                    Row {
                                        anchors.left: parent.left
                                        anchors.leftMargin: 42
                                        anchors.right: parent.right
                                        anchors.rightMargin: 12
                                        anchors.bottom: parent.bottom
                                        anchors.bottomMargin: 8
                                        height: 28
                                        spacing: 6
                                        visible: parent.actions.length > 0

                                        Repeater {
                                            model: notificationEntry.actions

                                            delegate: Rectangle {
                                                required property var modelData

                                                width: Math.min(140, actionLabel.implicitWidth + 18)
                                                height: parent.height
                                                radius: root.appearance.radius
                                                color: actionHover.hovered ? theme.accentHover : theme.accent

                                                HoverHandler {
                                                    id: actionHover
                                                }

                                                Text {
                                                    id: actionLabel

                                                    anchors.centerIn: parent
                                                    text: modelData.text
                                                    color: theme.background
                                                    font.pixelSize: root.appearance.textSize - 2
                                                    font.bold: true
                                                }

                                                TapHandler {
                                                    onTapped: {
                                                        modelData.invoke();
                                                        root.notificationHistory.remove(notificationEntry.modelData.id);
                                                    }
                                                }
                                            }
                                        }
                                    }

                                    TapHandler {
                                        onTapped: {
                                            if (parent.actions.length === 0)
                                                root.notificationHistory.remove(modelData.id);
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                Rectangle {
                    id: notificationScrollbar

                    visible: notificationScroller.contentHeight > notificationScroller.height
                    anchors.right: parent.right
                    anchors.rightMargin: 2
                    y: notificationScroller.visibleArea.yPosition
                        * (notificationScroller.height - notificationScrollbar.height)
                    width: 3
                    height: Math.max(28, notificationScroller.visibleArea.heightRatio
                        * notificationScroller.height)
                    radius: width / 2
                    color: theme.accent
                    opacity: 0.7
                }
            }
        }
    }
}
