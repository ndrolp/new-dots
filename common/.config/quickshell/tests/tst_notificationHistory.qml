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
            actions: [],
            lastGeneration: false,
            dismissCount: 0,
            dismiss() {
                this.dismissCount++;
            }
        }, properties || {});
    }

    function test_dismissingAStackDismissesEachOfItsNotifications() {
        const item = createTemporaryObject(history, this);
        const first = notification({ summary: "Download 1" });
        const second = notification({ summary: "Download 2" });
        const other = notification({ appName: "Discord", summary: "Message" });

        item.add(first);
        item.add(other);
        item.add(second);
        item.removeGroup("Firefox");

        compare([first.dismissCount, second.dismissCount, other.dismissCount], [1, 1, 0]);
    }

    function test_clearAllDismissesEveryNotification() {
        const item = createTemporaryObject(history, this);
        const first = notification({ summary: "Download 1" });
        const second = notification({ appName: "Discord", summary: "Message" });

        item.add(first);
        item.add(second);
        item.clear();

        compare([first.dismissCount, second.dismissCount], [1, 1]);
    }

    function test_theNotificationFallingPastTheFiftiethCardIsDismissed() {
        const item = createTemporaryObject(history, this);
        const sent = [];

        for (let index = 0; index < 51; index++) {
            sent.push(notification({ summary: "Message " + index }));
            item.add(sent[index]);
        }

        compare(item.items.length, 50);
        compare(sent[0].dismissCount, 1);
        compare(sent.slice(1).filter(each => each.dismissCount > 0).length, 0);
    }

    function test_aRepeatDismissesTheNotificationItReplaces() {
        const item = createTemporaryObject(history, this);
        const first = notification();
        const repeat = notification();

        item.add(first);
        item.add(repeat);

        compare(first.dismissCount, 1);
        compare(repeat.dismissCount, 0);
        compare(item.items[0].notification, repeat);
    }

    function test_openingTheControlCenterDoesNotDismissAnything() {
        const item = createTemporaryObject(history, this);
        const sent = notification();

        item.add(sent);
        item.markAllRead();

        compare(sent.dismissCount, 0);
    }

    function test_removingACardDismissesItsNotification() {
        const item = createTemporaryObject(history, this);
        const sent = notification();

        item.add(sent);
        item.remove(item.items[0].id);

        compare(sent.dismissCount, 1);
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
