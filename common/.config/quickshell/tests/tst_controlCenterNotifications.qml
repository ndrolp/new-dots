import QtQuick
import QtTest
import "../components/panels" as Panels
import "../config/Motion.js" as Motion

// The notifications in the control center: opening it marks everything read
// (the bell's badge clears), and the cards that arrived since you last looked
// stay highlighted until it closes. There is no search or Unread filter; the
// header keeps "Clear all" and do not disturb.
// Pointer events don't reach items under qmltestrunner offscreen, so buttons
// are pressed through their signals.
TestCase {
    name: "ControlCenterNotifications"
    width: 500
    height: 700
    visible: true
    when: windowShown

    QtObject {
        id: barAppearance

        property int radius: 12
        property int textSize: 13
        property bool doNotDisturb: false
        readonly property var motion: Motion.motion(true)
    }

    // Stands in for services/NotificationHistory.qml.
    Component {
        id: fakeHistory

        QtObject {
            property var items: []
            readonly property var groups: {
                const groups = [];
                items.forEach(item => {
                    let group = groups.find(candidate => candidate.appName === item.appName);
                    if (!group) {
                        group = { appName: item.appName, items: [] };
                        groups.push(group);
                    }
                    group.items.push(item);
                });
                return groups;
            }
            readonly property int unreadCount: items.filter(item => item.unread).length

            function markAllRead() {
                items = items.map(item => Object.assign({}, item, { unread: false }));
            }

            function remove(id) {
                items = items.filter(item => item.id !== id);
            }

            function clear() {
                items = [];
            }
        }
    }

    Component {
        id: body

        Panels.ControlCenterNotifications {
            appearance: barAppearance
            width: 400
        }
    }

    function entry(id, unread) {
        return {
            id: id,
            appName: "Firefox",
            summary: "Download " + id,
            body: "",
            notification: null,
            count: 1,
            unread: unread,
            timestamp: Date.now()
        };
    }

    function makeBody(items) {
        const history = createTemporaryObject(fakeHistory, this, { items: items });
        return createTemporaryObject(body, this, { notificationHistory: history });
    }

    function find(item, test) {
        if (test(item))
            return item;
        for (let i = 0; i < item.children.length; i++) {
            const found = find(item.children[i], test);
            if (found)
                return found;
        }
        return null;
    }

    function findAll(item, test, found) {
        found = found || [];
        if (test(item))
            found.push(item);
        for (let i = 0; i < item.children.length; i++)
            findAll(item.children[i], test, found);
        return found;
    }

    function cards(item) {
        return findAll(item, child => child.objectName === "notificationCard");
    }

    function highlightedSummaries(item) {
        return cards(item).filter(card => card.highlighted).map(card => card.entry.summary);
    }

    function button(item, label) {
        return find(item, child => child.label === label && child.activated !== undefined);
    }

    function test_openingMarksEverythingRead() {
        const item = makeBody([entry(1, true), entry(2, true)]);

        item.open = true;

        compare(item.notificationHistory.unreadCount, 0);
    }

    function test_cardsThatArrivedSinceYouLastLookedAreHighlightedUntilItCloses() {
        const item = makeBody([entry(1, true), entry(2, false)]);

        item.open = true;
        compare(highlightedSummaries(item), ["Download 1"]);

        item.open = false;
        compare(highlightedSummaries(item), []);
    }

    function test_reopeningHighlightsNothingYouAlreadySaw() {
        const item = makeBody([entry(1, true)]);

        item.open = true;
        item.open = false;
        item.open = true;

        compare(highlightedSummaries(item), []);
    }

    function test_aCardArrivingWhileOpenIsHighlighted() {
        const item = makeBody([entry(1, false)]);

        item.open = true;
        item.notificationHistory.items = [entry(2, true)].concat(item.notificationHistory.items);

        compare(highlightedSummaries(item), ["Download 2"]);
    }

    function test_thereIsNoSearchFieldOrUnreadFilter() {
        const item = makeBody([entry(1, true)]);

        compare(find(item, child => child instanceof TextInput), null);
        compare(find(item, child => child.text === "Unread" || child.label === "Unread"), null);
    }

    function test_clearAllRemovesEveryCard() {
        const item = makeBody([entry(1, true), entry(2, false)]);

        button(item, "Clear all").activated();

        compare(cards(item).length, 0);
    }

    function test_theDoNotDisturbButtonAsksToToggleIt() {
        const item = makeBody([]);
        let toggled = 0;
        item.doNotDisturbToggled.connect(() => toggled++);

        button(item, "DND off").activated();

        compare(toggled, 1);
    }
}
