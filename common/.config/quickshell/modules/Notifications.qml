import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import QtQuick
import "../components/panels" as Panels
import "../components/panels/ControlCenterNames.js" as Names
import "../components/bar/CapsuleRouting.js" as CapsuleRouting

// The shell's notification server and the toasts it shows; the
// notifications themselves are listed in the control center, the bell's
// popup. Every notification stays tracked while its card is in the history
// (NotificationHistory dismisses it when the card leaves), so its actions keep
// working after the toast hides. With notifications in the capsule on, a new
// one shows inside the focused monitor's capsule instead of as a toast
// (CapsuleRouting.notificationTarget), and those the capsule hands back show
// as toasts. Do not disturb stops the toasts, the capsule's and the sound
// only.
Scope {
    id: root

    required property var appearance
    required property var monitors
    required property var workspaceService
    required property var notificationHistory
    // The control center module, which opens it on the focused bar.
    required property var controlCenter
    // The bar module (modules/Bar.qml), for the bars and the focused monitor.
    required property var bar

    NotificationServer {
        id: notificationServer

        bodySupported: true
        bodyMarkupSupported: true
        actionsSupported: true
        inlineReplySupported: true
        imageSupported: true
        keepOnReload: true

        onNotification: notification => {
            // Decided before it is tracked, which is when its toast is.
            const capsule = !root.appearance.doNotDisturb && !notification.lastGeneration
                ? CapsuleRouting.notificationTarget(root.bar.bars(), root.bar.focusedMonitor()) : null;
            if (capsule !== null)
                toasts.leaveToCapsule(notification);
            notification.tracked = true;
            // An ongoing card leaves when its app ends the notification.
            notification.closed.connect(() => root.notificationHistory.closed(notification));
            // A replacement changes this object in place (no new
            // `notification`), so its card follows the new text.
            const updated = () => root.notificationHistory.updated(notification);
            notification.summaryChanged.connect(updated);
            notification.bodyChanged.connect(updated);
            notification.appIconChanged.connect(updated);
            notification.imageChanged.connect(updated);
            root.notificationHistory.add(notification);
            if (capsule !== null)
                capsule.showNotification(notification);

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
        id: toasts

        appearance: root.appearance
        monitors: root.monitors
        workspaceService: root.workspaceService
        notificationServer: notificationServer
    }

    Connections {
        target: root.bar

        function onCapsuleNotificationsReleased(notifications) {
            toasts.showToasts(notifications);
        }
    }

    IpcHandler {
        target: "notifications"

        function toggle() {
            root.controlCenter.toggle(Names.controlCenter.collapsed);
        }
    }
}
