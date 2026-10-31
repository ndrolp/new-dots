import QtQuick
import "../../config" as Config
import "." as Panels

// The notifications in the control center, newest first and grouped by app.
// Opening the control center marks everything read, so the bell's badge
// clears; the cards that arrived since you last looked stay highlighted
// until it closes. The header keeps "Clear all" and do not disturb.
Column {
    id: root

    required property var appearance
    required property var notificationHistory
    // Whether the control center is open.
    property bool open: false
    property double currentTime: Date.now()
    // The notifications unread when it opened: highlighted until it closes.
    property var freshIds: []
    readonly property var groups: notificationHistory.groups

    // The do not disturb button was pressed; the shell owns the setting.
    signal doNotDisturbToggled()

    spacing: 8

    onOpenChanged: {
        // A card arriving while open counts as seen once it closes.
        freshIds = open ? notificationHistory.items.filter(item => item.unread).map(item => item.id) : [];
        notificationHistory.markAllRead();
    }

    // Arrived since you last looked: unread when it opened, or arrived while open.
    function highlighted(entry) {
        return entry.unread || freshIds.indexOf(entry.id) !== -1;
    }

    function relativeTime(timestamp) {
        const elapsedSeconds = Math.max(0, Math.floor((currentTime - timestamp) / 1000));

        if (elapsedSeconds < 60)
            return "now";
        if (elapsedSeconds < 3600)
            return Math.floor(elapsedSeconds / 60) + "m";
        if (elapsedSeconds < 86400)
            return Math.floor(elapsedSeconds / 3600) + "h";
        return Math.floor(elapsedSeconds / 86400) + "d";
    }

    Config.Theme {
        id: theme
    }

    Timer {
        interval: 60000
        running: root.open
        repeat: true
        triggeredOnStart: true
        onTriggered: root.currentTime = Date.now()
    }

    Item {
        width: parent.width
        height: 30

        Panels.PopupTitle {
            anchors.left: parent.left
            anchors.right: headerButtons.left
            anchors.verticalCenter: parent.verticalCenter
            appearance: root.appearance
            text: "Notifications"
        }

        Row {
            id: headerButtons

            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 4

            Panels.PopupButton {
                id: doNotDisturbButton

                appearance: root.appearance
                width: doNotDisturbMetrics.width + 20
                label: root.appearance.doNotDisturb ? "DND on" : "DND off"
                labelColor: root.appearance.doNotDisturb ? theme.accent : theme.textMuted
                onActivated: root.doNotDisturbToggled()

                TextMetrics {
                    id: doNotDisturbMetrics

                    text: doNotDisturbButton.label
                    font.family: theme.fontFamily
                    font.pixelSize: doNotDisturbButton.labelSize
                }
            }

            Panels.PopupButton {
                id: clearButton

                appearance: root.appearance
                visible: root.groups.length > 0
                width: clearMetrics.width + 20
                label: "Clear all"
                labelColor: theme.textMuted
                onActivated: root.notificationHistory.clear()

                TextMetrics {
                    id: clearMetrics

                    text: clearButton.label
                    font.family: theme.fontFamily
                    font.pixelSize: clearButton.labelSize
                }
            }
        }
    }

    Panels.Text {
        visible: root.groups.length === 0
        width: parent.width
        height: 64
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        text: "No notifications"
        color: theme.textMuted
        font.pixelSize: root.appearance.textSize
    }

    Flickable {
        id: notificationScroller

        visible: root.groups.length > 0
        width: parent.width
        height: Math.min(520, notificationGroups.implicitHeight)
        contentWidth: width
        contentHeight: notificationGroups.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        Column {
            id: notificationGroups

            width: notificationScroller.width
            spacing: 12

            Repeater {
                model: root.groups

                delegate: Column {
                    required property var modelData

                    width: notificationGroups.width
                    spacing: 6

                    Panels.PopupLabel {
                        appearance: root.appearance
                        width: parent.width
                        text: modelData.appName
                    }

                    Repeater {
                        model: parent.modelData.items

                        delegate: Rectangle {
                            id: card

                            required property var modelData
                            readonly property var entry: modelData
                            readonly property bool highlighted: root.highlighted(modelData)
                            readonly property var actions: modelData.notification
                                ? modelData.notification.actions : []

                            objectName: "notificationCard"
                            width: notificationGroups.width
                            height: 70 + (actions.length > 0 ? 36 : 0)
                            radius: root.appearance.radius
                            color: cardHover.hovered ? theme.surfaceHover
                                : highlighted ? Qt.rgba(theme.accent.r, theme.accent.g, theme.accent.b, 0.12)
                                : theme.backgroundSecondary
                            border.width: highlighted ? 1 : 0
                            border.color: Qt.rgba(theme.accent.r, theme.accent.g, theme.accent.b, 0.35)

                            Behavior on color {
                                ColorAnimation { duration: root.appearance.motion.short }
                            }

                            HoverHandler {
                                id: cardHover
                            }

                            Panels.Text {
                                anchors.left: parent.left
                                anchors.leftMargin: 12
                                anchors.verticalCenter: parent.verticalCenter
                                text: "󰂚"
                                color: card.highlighted ? theme.accent : theme.textMuted
                                font.pixelSize: 18
                            }

                            Rectangle {
                                anchors.right: parent.right
                                anchors.rightMargin: 10
                                anchors.top: parent.top
                                anchors.topMargin: 8
                                visible: card.modelData.count > 1
                                width: 24
                                height: 20
                                radius: 10
                                color: theme.accent

                                Panels.Text {
                                    anchors.centerIn: parent
                                    text: card.modelData.count
                                    color: theme.background
                                    font.pixelSize: root.appearance.textSize - 3
                                }
                            }

                            Column {
                                anchors.left: parent.left
                                anchors.leftMargin: 42
                                anchors.right: parent.right
                                anchors.rightMargin: card.modelData.count > 1 ? 42 : 14
                                anchors.top: parent.top
                                anchors.topMargin: 11
                                spacing: 2

                                Panels.Text {
                                    width: parent.width
                                    text: card.modelData.summary || "Notification"
                                    color: theme.text
                                    elide: Text.ElideRight
                                    font.pixelSize: root.appearance.textSize
                                    font.bold: true
                                }

                                Panels.Text {
                                    width: parent.width
                                    visible: text !== ""
                                    text: card.modelData.body
                                    color: theme.textMuted
                                    textFormat: Text.PlainText
                                    elide: Text.ElideRight
                                    font.pixelSize: root.appearance.textSize - 2
                                }
                            }

                            Panels.Text {
                                anchors.right: parent.right
                                anchors.rightMargin: card.modelData.count > 1 ? 42 : 14
                                anchors.bottom: parent.bottom
                                anchors.bottomMargin: card.actions.length > 0 ? 38 : 9
                                text: root.relativeTime(card.modelData.timestamp)
                                color: theme.textMuted
                                font.pixelSize: root.appearance.textSize - 3
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
                                visible: card.actions.length > 0

                                Repeater {
                                    model: card.actions

                                    delegate: Rectangle {
                                        required property var modelData

                                        width: Math.min(140, actionLabel.implicitWidth + 18)
                                        height: parent.height
                                        radius: root.appearance.radius
                                        color: actionHover.hovered ? theme.accentHover : theme.accent

                                        HoverHandler {
                                            id: actionHover
                                        }

                                        Panels.Text {
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
                                                root.notificationHistory.remove(card.modelData.id);
                                            }
                                        }
                                    }
                                }
                            }

                            TapHandler {
                                onTapped: {
                                    if (card.actions.length === 0)
                                        root.notificationHistory.remove(card.modelData.id);
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
