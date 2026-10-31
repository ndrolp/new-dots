import QtQuick
import QtTest
import "../components/panels" as Panels
import "../config/Motion.js" as Motion

// The notifications in the control center: opening it marks everything read
// (the bell's badge clears), and the cards that arrived since you last looked
// stay highlighted until it closes. There is no search or Unread filter; the
// header keeps "Clear all"; do not disturb is a tile.
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
            readonly property var ongoing: items.filter(item => item.resident)
            readonly property var groups: {
                const groups = [];
                items.filter(item => !item.resident).forEach(item => {
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

            function removeGroup(appName) {
                items = items.filter(item => item.resident || item.appName !== appName);
            }

            function clear() {
                items = items.filter(item => item.resident);
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

    function ongoingEntry(id, appName) {
        return Object.assign(entry(id, false, appName), { summary: "Syncing " + id, resident: true });
    }

    function entry(id, unread, appName) {
        return {
            id: id,
            appName: appName || "Firefox",
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
        return findAll(item, child => child.objectName === "notificationCard" && child.visible);
    }

    function highlightedSummaries(item) {
        return cards(item).filter(card => card.highlighted).map(card => card.entry.summary);
    }

    function stacks(item) {
        return findAll(item, child => child.objectName === "notificationStack");
    }

    function texts(item) {
        return findAll(item, child => child.visible && typeof child.text === "string").map(child => child.text);
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

    function test_ongoingNotificationsArePinnedAboveTheRest() {
        const item = makeBody([entry(1, false), ongoingEntry(2, "Discord"), entry(3, false, "Discord")]);

        compare(cards(item).map(card => card.entry.summary), ["Syncing 2", "Download 1", "Download 3"]);
    }

    function test_clearAllKeepsOngoingNotifications() {
        const item = makeBody([entry(1, false), ongoingEntry(2), entry(3, false, "Discord")]);

        button(item, "Clear all").activated();

        compare(cards(item).map(card => card.entry.summary), ["Syncing 2"]);
        compare(item.notificationHistory.items.map(entry => entry.id), [2]);
    }

    function test_withOnlyOngoingNotificationsThereIsNothingToClear() {
        const item = makeBody([ongoingEntry(1)]);

        verify(!button(item, "Clear all").visible);
        compare(texts(item).indexOf("No notifications"), -1);
    }

    function test_dismissingAnOngoingCardRemovesIt() {
        const item = makeBody([ongoingEntry(1), entry(2, false)]);

        cards(item)[0].dismissed();

        compare(item.notificationHistory.items.map(entry => entry.id), [2]);
    }

    function test_aDismissedCardLeavesTheHistory() {
        const item = makeBody([entry(1, false), entry(2, false, "Discord")]);

        cards(item)[0].dismissed();

        compare(item.notificationHistory.items.map(item => item.id), [2]);
    }

    function test_aCardAskingToCloseClosesTheControlCenter() {
        const item = makeBody([entry(1, false)]);
        let closeRequests = 0;
        item.closeRequested.connect(() => closeRequests++);

        cards(item)[0].closeRequested();

        compare(closeRequests, 1);
    }

    // Do not disturb is a tile of the control center now, not a header button.
    function test_theHeaderHasNoDoNotDisturbButton() {
        const item = makeBody([]);

        compare(button(item, "DND off"), null);
        compare(button(item, "DND on"), null);
    }

    function test_twoNotificationsFromOneAppShowAsAStackWithTheNewestCard() {
        const item = makeBody([entry(2, false), entry(1, false), entry(3, false, "Discord")]);

        compare(stacks(item).length, 1);
        compare(cards(stacks(item)[0]).map(card => card.entry.summary), ["Download 2"]);
        verify(texts(stacks(item)[0]).indexOf("+1 more") !== -1);
    }

    function test_anAppWithASingleNotificationShowsAPlainCard() {
        const item = makeBody([entry(1, false), entry(2, false, "Discord")]);

        compare(stacks(item).length, 0);
        compare(cards(item).length, 2);
        compare(texts(item).filter(text => text.endsWith(" more")), []);
    }

    function test_tappingAStackShowsEveryCardOfThatApp() {
        const item = makeBody([entry(3, false), entry(2, false), entry(1, false)]);

        stacks(item)[0].tap();

        compare(cards(item).map(card => card.entry.summary), ["Download 3", "Download 2", "Download 1"]);
        compare(texts(item).filter(text => text.endsWith(" more")), []);
    }

    function test_showLessCollapsesAnExpandedStackAgain() {
        const item = makeBody([entry(2, false), entry(1, false)]);

        stacks(item)[0].tap();
        button(item, "Show less").activated();

        compare(cards(item).map(card => card.entry.summary), ["Download 2"]);
        verify(texts(item).indexOf("+1 more") !== -1);
    }

    function test_anExpandedStackStaysExpandedWhenOneOfItsCardsIsDismissed() {
        const item = makeBody([entry(3, false), entry(2, false), entry(1, false)]);

        stacks(item)[0].tap();
        cards(item)[0].dismissed();

        compare(cards(item).map(card => card.entry.summary), ["Download 2", "Download 1"]);
    }

    function test_reopeningTheControlCenterCollapsesTheStacks() {
        const item = makeBody([entry(2, false), entry(1, false)]);

        item.open = true;
        stacks(item)[0].tap();
        item.open = false;

        compare(cards(item).map(card => card.entry.summary), ["Download 2"]);
    }

    function test_swipingACollapsedStackDismissesEveryNotificationOfThatApp() {
        const item = makeBody([entry(3, false), entry(2, false, "Discord"), entry(1, false)]);
        const stack = stacks(item)[0];

        stack.swipeOffset = -stack.width * 0.5;
        stack.swipeReleased();

        tryVerify(() => item.notificationHistory.items.length === 1);
        compare(item.notificationHistory.items.map(entry => entry.id), [2]);
    }

    function test_aShortSwipeSnapsTheStackBack() {
        const item = makeBody([entry(2, false), entry(1, false)]);
        const stack = stacks(item)[0];

        stack.swipeOffset = stack.width * 0.2;
        stack.swipeReleased();

        tryCompare(stack, "swipeOffset", 0);
        wait(50);
        compare(item.notificationHistory.items.length, 2);
    }

    function test_theCollapsedStackIsHighlightedWhenAnyOfItsCardsArrivedSinceYouLastLooked() {
        const item = makeBody([entry(2, false), entry(1, true)]);

        item.open = true;

        compare(highlightedSummaries(item), ["Download 2"]);
    }
}
