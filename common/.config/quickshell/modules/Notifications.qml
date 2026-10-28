import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import QtQuick
import "../components/panels" as Panels

// The shell's notification server, the popups it shows and the notification
// panel. Do not disturb stops both the popups and the sound.
Feature {
    id: root

    required property var appearance
    required property var notificationHistory
    // The bar the panel attaches to when IPC opens it before any bar asked.
    property var fallbackWindow: null
    property var window: null

    // The notifications button on a bar: the panel moves to that bar and
    // opens, or closes.
    function toggleOn(panelWindow) {
        window = panelWindow;
        open = !open;
    }

    // A bar came up: the panel attaches to the first one.
    function offerWindow(panelWindow) {
        if (window === null)
            window = panelWindow;
    }

    NotificationServer {
        id: notificationServer

        bodySupported: true
        bodyMarkupSupported: true
        actionsSupported: true
        imageSupported: true
        keepOnReload: true

        onNotification: notification => {
            notification.tracked = !root.appearance.doNotDisturb;
            root.notificationHistory.add(notification);

            if (!root.appearance.doNotDisturb)
                notificationSound.exec(["pw-play", "/usr/share/sounds/freedesktop/stereo/message.oga"]);
        }
    }

    Connections {
        target: root.appearance

        function onDoNotDisturbChanged() {
            if (!root.appearance.doNotDisturb)
                return;

            notificationServer.trackedNotifications.forEach(notification => {
                notification.tracked = false;
            });
        }
    }

    Process {
        id: notificationSound
    }

    Panels.NotificationPopup {
        appearance: root.appearance
        notificationServer: notificationServer
    }

    Panels.NotificationPanel {
        appearance: root.appearance
        notificationServer: notificationServer
        notificationHistory: root.notificationHistory
        open: root.open
        targetWindow: root.window

        onCloseRequested: root.open = false
    }

    IpcHandler {
        target: "notifications"

        function toggle() {
            if (root.window === null)
                root.window = root.fallbackWindow;
            root.toggle();
        }
    }
}
