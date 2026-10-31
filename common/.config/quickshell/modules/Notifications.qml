import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import QtQuick
import "../components/panels" as Panels

// The shell's notification server and the on-screen popups it shows; the
// notifications themselves are listed in the control center, the bell's
// popup. Do not disturb stops both the popups and the sound.
Scope {
    id: root

    required property var appearance
    required property var notificationHistory
    // The bar module, which opens the control center on the focused bar.
    required property var bar

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

    IpcHandler {
        target: "notifications"

        function toggle() {
            root.bar.toggleControlCenter("collapsed");
        }
    }
}
