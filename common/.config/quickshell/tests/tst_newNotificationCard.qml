import QtQuick
import QtTest
import "../components/panels" as Panels
import "../components/panels/NotificationCard.js" as NotificationCard
import "../config/Motion.js" as Motion

// The card a new notification shows as, a toast or inside the capsule: how
// long it shows, its actions and inline reply, and the "+N" of the ones
// waiting in the capsule.
// Pointer events don't reach items under qmltestrunner offscreen, so taps are
// given to the card through the functions its handlers call.
TestCase {
    name: "NewNotificationCard"
    width: 500
    height: 400
    visible: true
    when: windowShown

    // A toast shows for the timeout its app asks for, else 5 s; a critical
    // one stays until it is dismissed (0: no timeout).
    function test_howLongAToastShows_data() {
        return [
            { tag: "the app's timeout", notification: { expireTimeout: 8000 }, timeout: 8000 },
            { tag: "no timeout asked", notification: { expireTimeout: -1 }, timeout: 5000 },
            { tag: "a timeout of 0", notification: { expireTimeout: 0 }, timeout: 5000 },
            { tag: "critical", notification: { expireTimeout: 8000, critical: true }, timeout: 0 }
        ];
    }

    function test_howLongAToastShows(data) {
        compare(NotificationCard.newNotificationTimeout(data.notification), data.timeout);
    }

    // Stands in for a Quickshell NotificationAction.
    Component {
        id: fakeAction

        QtObject {
            property string identifier: ""
            property string text: ""
            property int invoked: 0

            function invoke() {
                invoked++;
            }
        }
    }

    // Stands in for a Quickshell Notification.
    Component {
        id: fakeNotification

        QtObject {
            property string appName: "Chat"
            property string appIcon: ""
            property string image: ""
            property string summary: "Ana"
            property string body: "Lunch?"
            property var actions: []
            property int expireTimeout: -1
            // NotificationUrgency: 1 normal, 2 critical.
            property int urgency: 1
            property bool hasInlineReply: false
            property string inlineReplyPlaceholder: ""
            property var replies: []

            function sendInlineReply(text) {
                replies = replies.concat([text]);
            }
        }
    }

    Component {
        id: card

        Panels.NewNotificationCard {
            width: 380
            appearance: ({ radius: 8, textSize: 13, motion: Motion.motion(true) })
        }
    }

    SignalSpy {
        id: endedSpy

        signalName: "ended"
    }

    function action(identifier, text) {
        return createTemporaryObject(fakeAction, this, { identifier: identifier, text: text || identifier });
    }

    function notification(properties) {
        return createTemporaryObject(fakeNotification, this, properties || {});
    }

    function makeCard(properties) {
        const item = createTemporaryObject(card, this, properties);
        endedSpy.clear();
        endedSpy.target = item;
        return item;
    }

    function findAll(item, test, found) {
        found = found || [];
        if (test(item))
            found.push(item);
        for (let i = 0; i < item.children.length; i++)
            findAll(item.children[i], test, found);
        return found;
    }

    function shownText(item, text) {
        return findAll(item, child => child.text === text && child.visible && child.font !== undefined
            && !(child instanceof TextInput))[0] || null;
    }

    function actionButtons(item) {
        return findAll(item, child => child.objectName === "toastActionButton");
    }

    function test_tappingItRunsItsDefaultActionAndEndsIt() {
        const open = action("default", "Open");
        const item = makeCard({ notification: notification({ actions: [open] }) });

        item.tap();

        compare(open.invoked, 1);
        compare(endedSpy.count, 1);
    }

    // Its other actions are buttons; pressing one runs it and ends the card.
    function test_itsActionsAreButtonsThatRunAndEndIt() {
        const open = action("default", "Open");
        const markRead = action("mark-read", "Mark as read");
        const item = makeCard({ notification: notification({ actions: [open, markRead] }) });

        compare(actionButtons(item).map(button => button.label), ["Mark as read"]);

        item.invokeAction(markRead);
        compare(markRead.invoked, 1);
        compare(open.invoked, 0);
        compare(endedSpy.count, 1);
    }

    function replyField(item) {
        return findAll(item, child => child.objectName === "toastReplyField")[0];
    }

    // Only a notification whose app asks for an inline reply has one.
    function test_anInlineReplyShowsOnlyWhenItsAppAsksForOne() {
        verify(!replyField(makeCard({ notification: notification() })).visible);

        const item = makeCard({ notification: notification({ hasInlineReply: true,
            inlineReplyPlaceholder: "Message Ana" }) });
        verify(replyField(item).visible);
        compare(replyField(item).placeholderText, "Message Ana");
    }

    // Typing a reply and pressing Enter sends it and ends the card; an empty
    // one sends nothing.
    function test_enterSendsTheInlineReplyAndEndsIt() {
        const replied = notification({ hasInlineReply: true });
        const item = makeCard({ notification: replied });
        const field = replyField(item);

        field.forceActiveFocus();
        verify(item.replying);
        keyClick(Qt.Key_Return);
        compare(replied.replies, []);
        compare(endedSpy.count, 0);

        keyClick("o");
        keyClick("k");
        keyClick(Qt.Key_Return);
        compare(replied.replies, ["ok"]);
        compare(endedSpy.count, 1);
    }

    // It ends by itself once its timeout runs out, while it runs.
    function test_itEndsWhenItsTimeoutRunsOut() {
        const item = makeCard({ notification: notification({ expireTimeout: 150 }) });

        tryCompare(endedSpy, "count", 1, 2000);
    }

    function test_itWaitsWhileItIsntRunning() {
        const item = makeCard({ notification: notification({ expireTimeout: 150 }), running: false });

        wait(400);
        compare(endedSpy.count, 0);
    }

    // A critical one stays until it is dismissed, with no timeout line.
    function test_aCriticalOneStaysUntilDismissed() {
        const item = makeCard({ notification: notification({ expireTimeout: 150, urgency: 2 }) });

        wait(400);
        compare(endedSpy.count, 0);
        compare(item.lifetimeProgress, 1);
    }

    // Inside the capsule the next notification takes the card with its whole
    // timeout, out of any reply left half written.
    function test_theNextNotificationStartsAfresh() {
        const item = makeCard({ notification: notification({ expireTimeout: 2000, hasInlineReply: true }) });

        tryVerify(() => item.lifetimeProgress < 0.9, 1000);
        replyField(item).forceActiveFocus();
        keyClick("h");
        item.notification = notification({ hasInlineReply: true });

        compare(item.lifetimeProgress, 1);
        verify(!item.replying);
        compare(replyField(item).text, "");
    }

    // Inside the capsule it counts the ones waiting behind it.
    function test_itCountsTheOnesWaitingBehindIt() {
        const item = makeCard({ notification: notification(), waiting: 2 });

        verify(shownText(item, "+2"));
        item.waiting = 0;
        verify(!shownText(item, "+0"));
    }

    function test_closingItEndsItWithoutRunningAnything() {
        const open = action("default", "Open");
        const item = makeCard({ notification: notification({ actions: [open] }) });

        item.close();

        compare(open.invoked, 0);
        compare(endedSpy.count, 1);
    }
}
