import QtQuick

// The control center: the popup of the bell bar element (saved id
// "notifications"), holding today's notifications.
BarPopup {
    id: root

    required property var notificationHistory

    popup: "controlCenter"
    implicitWidth: 424

    ControlCenterNotifications {
        width: parent.width
        appearance: root.appearance
        notificationHistory: root.notificationHistory
        open: root.open

        onDoNotDisturbToggled: root.popups.doNotDisturbToggled()
    }
}
