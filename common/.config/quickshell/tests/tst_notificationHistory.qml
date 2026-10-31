import QtQuick
import QtTest
import "../services" as Services

// The notification history behind the control center: what it keeps of a
// notification, so its card can still show it once the server has let the
// notification go.
TestCase {
    name: "NotificationHistory"
    when: windowShown

    Component {
        id: history

        Services.NotificationHistory {}
    }

    function notification(properties) {
        return Object.assign({
            appName: "Firefox",
            appIcon: "",
            image: "",
            summary: "Download finished",
            body: "",
            actions: []
        }, properties || {});
    }

    function test_anEntryKeepsTheAppIconAndImageItWasSentWith() {
        const item = createTemporaryObject(history, this);

        item.add(notification({ appIcon: "firefox", image: "image://qsimage/1" }));

        compare(item.items[0].appIcon, "firefox");
        compare(item.items[0].image, "image://qsimage/1");
    }

    function test_aRepeatedNotificationKeepsTheNewestIconAndImage() {
        const item = createTemporaryObject(history, this);

        item.add(notification({ appIcon: "firefox", image: "image://qsimage/1" }));
        item.add(notification({ appIcon: "firefox-nightly", image: "image://qsimage/2" }));

        compare(item.items.length, 1);
        compare(item.items[0].count, 2);
        compare(item.items[0].appIcon, "firefox-nightly");
        compare(item.items[0].image, "image://qsimage/2");
    }
}
