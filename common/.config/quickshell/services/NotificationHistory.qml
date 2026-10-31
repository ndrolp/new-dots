import QtQuick

QtObject {
    id: root

    property var items: []
    // The app stacks, without the ongoing notifications.
    property var groups: []
    // The ongoing notifications (the `resident` hint), newest first: pinned
    // above the stacks, and neither "Clear all" nor a stack swipe removes them.
    property var ongoing: []
    property int nextId: 0
    readonly property int unreadCount: items.reduce((count, item) => count
        + (item.unread ? item.count : 0), 0)

    // The app a notification is grouped (and stacked) under.
    function groupName(item) {
        return item.appName || "Unknown application";
    }

    // Every change goes through here, so a notification whose card leaves
    // the history (removed, its group or all cleared, replaced by a repeat,
    // or past the 50-entry cap) is dismissed: the server keeps a notification
    // alive exactly as long as its card is listed. `alreadyClosed`, the
    // notification the server just closed, isn't dismissed again.
    function updateItems(updatedItems, alreadyClosed) {
        const kept = updatedItems.map(item => item.notification);

        items.forEach(item => {
            if (item.notification && item.notification !== alreadyClosed
                    && kept.indexOf(item.notification) < 0)
                item.notification.dismiss();
        });

        items = updatedItems;

        const groupedItems = [];

        items.filter(item => !item.resident).forEach(item => {
            const appName = groupName(item);
            let groupIndex = groupedItems.findIndex(group => group.appName === appName);

            if (groupIndex < 0) {
                groupIndex = groupedItems.length;
                groupedItems.push({
                    appName: appName,
                    items: []
                });
            }

            groupedItems[groupIndex].items.push(item);
        });

        groups = groupedItems;
        ongoing = items.filter(item => item.resident);
    }

    // An entry keeps the notification's text, app icon and image as plain
    // values next to the Notification object itself (`notification`, for its
    // actions), which stays alive until the card leaves the history.
    // After a shell reload the server sends its kept notifications again
    // (`lastGeneration`), oldest first, so adding them rebuilds the history;
    // they come back read, since they were there before the reload.
    function add(notification) {
        const appName = notification.appName || "";
        const summary = notification.summary || "";
        const body = notification.body || "";
        const existingIndex = items.findIndex(item => item.appName === appName
            && item.summary === summary && item.body === body);
        const existing = existingIndex >= 0 ? items[existingIndex] : null;
        const entry = {
            id: existing ? existing.id : nextId++,
            appName: appName,
            appIcon: notification.appIcon || "",
            image: notification.image || "",
            summary: summary,
            body: body,
            notification: notification,
            resident: !!notification.resident,
            count: existing ? existing.count + 1 : 1,
            unread: !notification.lastGeneration,
            timestamp: Date.now()
        };
        const rest = items.filter((item, index) => index !== existingIndex);

        updateItems(capped([entry].concat(rest)));
    }

    // The newest 50 ordinary cards; ongoing ones don't count and always stay.
    function capped(list) {
        let ordinary = 0;
        return list.filter(item => item.resident || ordinary++ < 50);
    }

    function markAllRead() {
        if (unreadCount === 0)
            return;

        updateItems(items.map(item => Object.assign({}, item, { unread: false })));
    }

    function remove(id) {
        updateItems(items.filter(item => item.id !== id));
    }

    // Dismisses a whole app stack: every notification of that group except
    // its ongoing ones, which aren't in the stack.
    function removeGroup(appName) {
        updateItems(items.filter(item => item.resident || groupName(item) !== appName));
    }

    // The server closed `notification` (the app ended it, or it was
    // dismissed). An ongoing card leaves with it, since "Clear all" can't
    // remove it; any other card stays, as text, until you dismiss it.
    function closed(notification) {
        const entry = items.find(item => item.notification === notification);
        if (!entry || !entry.resident)
            return;

        updateItems(items.filter(item => item !== entry), notification);
    }

    // The app replaced `notification` (`replaces_id`): the server changes the
    // same object in place and doesn't send it again, so its card takes the
    // new text, icon and image where it is (an ongoing card's progress).
    function updated(notification) {
        if (!items.some(item => item.notification === notification))
            return;

        updateItems(items.map(item => item.notification !== notification ? item
            : Object.assign({}, item, {
                appIcon: notification.appIcon || "",
                image: notification.image || "",
                summary: notification.summary || "",
                body: notification.body || ""
            })));
    }

    // "Clear all": every notification but the ongoing ones.
    function clear() {
        updateItems(items.filter(item => item.resident));
    }
}
