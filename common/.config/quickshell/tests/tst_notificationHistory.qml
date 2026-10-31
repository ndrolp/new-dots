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

    function summaries(group) {
        return group.items.map(entry => entry.summary);
    }

    function test_notificationsFromOneAppGroupTogetherNewestFirst() {
        const item = createTemporaryObject(history, this);

        item.add(notification({ appName: "Firefox", summary: "Download 1" }));
        item.add(notification({ appName: "Discord", summary: "Message" }));
        item.add(notification({ appName: "Firefox", summary: "Download 2" }));

        compare(item.groups.map(group => group.appName), ["Firefox", "Discord"]);
        compare(summaries(item.groups[0]), ["Download 2", "Download 1"]);
        compare(summaries(item.groups[1]), ["Message"]);
    }

    function test_dismissingAGroupRemovesEveryNotificationOfThatApp() {
        const item = createTemporaryObject(history, this);

        item.add(notification({ appName: "Firefox", summary: "Download 1" }));
        item.add(notification({ appName: "Discord", summary: "Message" }));
        item.add(notification({ appName: "Firefox", summary: "Download 2" }));

        item.removeGroup("Firefox");

        compare(item.items.map(entry => entry.summary), ["Message"]);
        compare(item.groups.map(group => group.appName), ["Discord"]);
    }

    function test_dismissingTheGroupOfNotificationsWithNoAppNameRemovesThem() {
        const item = createTemporaryObject(history, this);

        item.add(notification({ appName: "", summary: "Anonymous 1" }));
        item.add(notification({ appName: "", summary: "Anonymous 2" }));
        item.add(notification({ appName: "Discord", summary: "Message" }));

        item.removeGroup(item.groups[1].appName);

        compare(item.items.map(entry => entry.summary), ["Message"]);
    }
}
