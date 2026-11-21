import QtQuick
import "CapsuleNotificationQueue.js" as CapsuleNotificationQueue

// The notifications one capsule shows, with notifications in the capsule on:
// the one shown and those waiting behind it (CapsuleNotificationQueue.js).
Item {
    id: root

    property var queue: CapsuleNotificationQueue.empty
    // The live Notification shown, or null.
    readonly property var shown: queue.shown
    // How many wait behind it, the "+N".
    readonly property int waiting: queue.waiting.length

    // The capsule can't show these any more: they show as toasts instead,
    // oldest first.
    signal released(var notifications)

    // `notification` is new: it shows at once, the one it replaces waits.
    function show(notification) {
        queue = CapsuleNotificationQueue.arrived(queue, notification);
        // Its app closing it, or its card leaving the control center, ends it.
        notification.closed.connect(() => root.end(notification));
    }

    // `notification`'s card is done with, or it closed: the next one shows.
    function end(notification) {
        queue = CapsuleNotificationQueue.ended(queue, notification);
    }

    // Hands every notification over to show as toasts.
    function release() {
        const notifications = CapsuleNotificationQueue.all(queue);
        queue = CapsuleNotificationQueue.empty;
        if (notifications.length > 0)
            released(notifications);
    }

    // Drops them all, as Do Not Disturb does with toasts.
    function clear() {
        queue = CapsuleNotificationQueue.empty;
    }
}
