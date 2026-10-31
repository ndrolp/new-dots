import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import QtQuick
import "../components/panels" as Panels

// The shell's notification server and the toasts it shows; the
// notifications themselves are listed in the control center, the bell's
// popup. Every notification stays tracked while its card is in the history
// (NotificationHistory dismisses it when the card leaves), so its actions keep
// working after the toast hides. Do not disturb stops the toasts and the
// sound only.
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
            notification.tracked = true;
            // An ongoing card leaves when its app ends the notification.
            notification.closed.connect(() => root.notificationHistory.closed(notification));
            root.notificationHistory.add(notification);

            // Kept notifications sent again after a reload rebuild the
            // history quietly.
            if (!root.appearance.doNotDisturb && !notification.lastGeneration)
                notificationSound.exec(["pw-play", "/usr/share/sounds/freedesktop/stereo/message.oga"]);
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
