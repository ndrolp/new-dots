import QtQuick
import "." as Panels

// The ongoing notifications, on top of the control center in both stages:
// the media card while a player is active, then the notifications with the
// `resident` hint, newest first. They are never stacked and "Clear all"
// leaves them; × and a swipe still dismiss one. With nothing ongoing it
// takes no room.
Column {
    id: root

    required property var appearance
    required property var notificationHistory
    // The active player (MediaCard.activePlayer), or null.
    property var player: null
    // Whether the control center is open; the cards' times tick while it is.
    property bool open: false
    // The notifications highlighted in the list below (arrived since you
    // last looked), so an ongoing one is highlighted the same way.
    property var highlightedIds: []
    property double currentTime: Date.now()
    readonly property var ongoing: notificationHistory.ongoing

    // A card ran its default action: the control center should close.
    signal closeRequested()

    spacing: 8

    Timer {
        interval: 60000
        running: root.open
        repeat: true
        triggeredOnStart: true
        onTriggered: root.currentTime = Date.now()
    }

    Panels.ControlCenterMediaCard {
        width: root.width
        appearance: root.appearance
        player: root.player
    }

    Repeater {
        model: root.ongoing

        delegate: Panels.NotificationCard {
            required property var modelData

            width: root.width
            appearance: root.appearance
            record: modelData
            highlighted: root.highlightedIds.indexOf(modelData.id) !== -1
            currentTime: root.currentTime

            onDismissed: root.notificationHistory.remove(modelData.id)
            onCloseRequested: root.closeRequested()
        }
    }
}
