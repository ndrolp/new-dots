import QtQuick
import "../../config" as Config
import "." as Panels

// The notifications in the control center, newest first and grouped by app.
// Opening the control center marks everything read, so the bell's badge
// clears; the cards that arrived since you last looked stay highlighted
// until it closes. The header keeps "Clear all"; do not disturb is a tile.
// Each notification is a NotificationCard.
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

    // A card ran its default action: the control center should close.
    signal closeRequested()

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

                        delegate: Panels.NotificationCard {
                            required property var modelData

                            width: notificationGroups.width
                            appearance: root.appearance
                            entry: modelData
                            highlighted: root.highlighted(modelData)
                            currentTime: root.currentTime

                            onDismissed: root.notificationHistory.remove(modelData.id)
                            onCloseRequested: root.closeRequested()
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
