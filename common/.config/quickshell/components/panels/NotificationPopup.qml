import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Effects
import "../../config" as Config
import "../IconSource.js" as IconSource

PanelWindow {
    id: root

    required property var notificationServer
    required property var appearance

    screen: Quickshell.screens.values.length > 0 ? Quickshell.screens.values[0] : null
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    implicitWidth: 404
    implicitHeight: notificationList.implicitHeight + 24
    readonly property bool bottomAligned: root.appearance.notificationPopupLocation.indexOf("bottom") === 0
    readonly property bool rightAligned: root.appearance.notificationPopupLocation.indexOf("right") !== -1

    WlrLayershell.namespace: "ndro-shell-notifications"
    mask: Region {
        item: notificationList
    }

    anchors {
        top: !root.bottomAligned
        bottom: root.bottomAligned
        left: true
    }

    margins {
        top: root.bottomAligned ? 0 : root.appearance.barHeight + root.appearance.spacing
        bottom: root.bottomAligned ? root.appearance.spacing : 0
        left: !screen ? 0 : root.rightAligned
            ? screen.width - root.implicitWidth - root.appearance.horizontalPadding
            : root.appearance.notificationPopupLocation.indexOf("left") !== -1
                ? root.appearance.horizontalPadding
                : (screen.width - root.implicitWidth) / 2
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

        // One delegate per notification the server keeps, i.e. per card in
        // the control center; only the toasts still showing are visible.
        Repeater {
            model: root.notificationServer.trackedNotifications

            delegate: Rectangle {
                id: notificationCard

                required property var modelData
                // A toast shows when its notification arrives, unless do not
                // disturb is on or it was only sent again after a reload. It
                // hides when it times out, is tapped or closed, or do not
                // disturb turns on; the notification lives on in the control
                // center until its card leaves the history.
                property bool toastShown: !root.appearance.doNotDisturb
                    && !modelData.lastGeneration
                property real reveal: 0
                readonly property int timeout: modelData.expireTimeout > 0
                    ? modelData.expireTimeout : 5000
                property real lifetimeProgress: 1

                function hide() {
                    toastShown = false;
                }

                visible: toastShown
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

                Component.onCompleted: {
                    // Breaks the binding: the toast's fate is decided once.
                    toastShown = toastShown;
                    reveal = 1;
                }

                Connections {
                    target: root.appearance

                    function onDoNotDisturbChanged() {
                        if (root.appearance.doNotDisturb)
                            notificationCard.hide();
                    }
                }

                Behavior on reveal {
                    NumberAnimation {
                        duration: root.appearance.motion.medium
                        easing.type: root.appearance.motion.easing
                    }
                }

                Timer {
                    interval: 50
                    running: notificationCard.toastShown
                    repeat: true
                    onTriggered: {
                        notificationCard.lifetimeProgress = Math.max(0,
                            notificationCard.lifetimeProgress - interval / notificationCard.timeout);

                        if (notificationCard.lifetimeProgress === 0)
                            notificationCard.hide();
                    }
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
                                    ? IconSource.forName(notificationCard.modelData.appIcon) : ""
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
                        ColorAnimation { duration: root.appearance.motion.short }
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
                        onTapped: notificationCard.hide()
                    }
                }

                TapHandler {
                    onTapped: notificationCard.hide()
                }

                Rectangle {
                    anchors.left: parent.left
                    anchors.bottom: parent.bottom
                    width: parent.width * notificationCard.lifetimeProgress
                    height: 3
                    radius: root.appearance.radius
                    color: theme.accent
                }
            }
        }
    }
}
