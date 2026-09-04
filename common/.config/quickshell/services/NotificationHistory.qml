import QtQuick

QtObject {
    id: root

    property var items: []
    property var groups: []
    property int nextId: 0

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
                count: existing.count + 1
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
            count: 1
        };
        const updatedItems = [entry].concat(items);

        updateItems(updatedItems.slice(0, 50));
    }

    function remove(id) {
        updateItems(items.filter(item => item.id !== id));
    }

    function clear() {
        updateItems([]);
    }
}
