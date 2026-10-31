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

    function add(notification) {
        const appName = notification.appName || "";
        const summary = notification.summary || "";
        const body = notification.body || "";
        const timestamp = Date.now();
        const existingIndex = items.findIndex(item => item.appName === appName
            && item.summary === summary && item.body === body);

        if (existingIndex >= 0) {
            const updatedItems = items.slice();
            const existing = updatedItems[existingIndex];
            updatedItems.splice(existingIndex, 1);
            updatedItems.unshift({
                id: existing.id,
                appName: appName,
                summary: summary,
                body: body,
                notification: notification,
                count: existing.count + 1,
                unread: true,
                timestamp: timestamp
            });
            updateItems(updatedItems);
            return;
        }

        const entry = {
            id: nextId++,
            appName: appName,
            summary: summary,
            body: body,
            notification: notification,
            count: 1,
            unread: true,
            timestamp: timestamp
        };
        updateItems([entry].concat(items).slice(0, 50));
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
