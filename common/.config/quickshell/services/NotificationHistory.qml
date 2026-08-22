import QtQuick

QtObject {
    id: root

    property var items: []
    property int nextId: 0

    function add(notification) {
        const entry = {
            id: nextId++,
            appName: notification.appName || "",
            summary: notification.summary || "",
            body: notification.body || ""
        };
        const updatedItems = [entry].concat(items);

        items = updatedItems.slice(0, 50);
    }

    function remove(id) {
        items = items.filter(item => item.id !== id);
    }

    function clear() {
        items = [];
    }
}
