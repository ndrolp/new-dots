import QtQuick

QtObject {
    id: root

    property var items: []
    property var groups: []
    property int nextId: 0
    readonly property int unreadCount: items.reduce((count, item) => count
        + (item.unread ? item.count : 0), 0)

    function updateItems(updatedItems) {
        items = updatedItems;

        const groupedItems = [];

        items.forEach(item => {
            const appName = item.appName || "Unknown application";
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
    }

    // An entry keeps the notification's text, app icon and image as plain
    // values, since the Notification object (`notification`, for its actions)
    // goes away once the server lets it go.
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
            count: existing ? existing.count + 1 : 1,
            unread: true,
            timestamp: Date.now()
        };
        const rest = items.filter((item, index) => index !== existingIndex);

        updateItems([entry].concat(rest).slice(0, 50));
    }

    function markAllRead() {
        if (unreadCount === 0)
            return;

        updateItems(items.map(item => Object.assign({}, item, { unread: false })));
    }

    function remove(id) {
        updateItems(items.filter(item => item.id !== id));
    }

    function clear() {
        updateItems([]);
    }
}
