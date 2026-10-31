import QtQuick
import QtTest
import "../components/panels" as Panels
import "../config/Motion.js" as Motion

// A notification card in the control center: what tapping it does (run the
// default action, or expand when it has none), its action buttons, the ×,
// and how far a sideways swipe has to go to dismiss it.
// Pointer events don't reach items under qmltestrunner offscreen, so taps and
// drags are given to the card through the functions its handlers call.
TestCase {
    name: "NotificationCard"
    width: 500
    height: 400
    visible: true
    when: windowShown

    QtObject {
        id: barAppearance

        property int radius: 12
        property int textSize: 13
        readonly property var motion: Motion.motion(true)
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

    Component {
        id: card

        Panels.NotificationCard {
            appearance: barAppearance
            width: 400
        }
    }

    SignalSpy {
        id: dismissedSpy

        signalName: "dismissed"
    }

    SignalSpy {
        id: closeSpy

        signalName: "closeRequested"
    }

    function action(identifier, text) {
        return createTemporaryObject(fakeAction, this, { identifier: identifier, text: text || identifier });
    }

    function entry(properties) {
        return Object.assign({
            id: 1,
            appName: "Firefox",
            appIcon: "",
            image: "",
            summary: "Download finished",
            body: "",
            notification: null,
            count: 1,
            unread: false,
            timestamp: Date.now()
        }, properties || {});
    }

    function makeCard(properties) {
        const item = createTemporaryObject(card, this, { entry: entry(properties) });
        dismissedSpy.clear();
        closeSpy.clear();
        dismissedSpy.target = item;
        closeSpy.target = item;
        return item;
    }

    function test_tappingACardRunsItsDefaultActionRemovesItAndClosesTheControlCenter() {
        const defaultAction = action("default", "Open");
        const item = makeCard({ notification: { actions: [defaultAction] } });

        item.tap();

        compare(defaultAction.invoked, 1);
        compare(dismissedSpy.count, 1);
        compare(closeSpy.count, 1);
    }

    function test_tappingACardWithoutADefaultActionExpandsItAndKeepsItThere() {
        const reply = action("reply", "Reply");
        const item = makeCard({ body: "A long body", notification: { actions: [reply] } });

        item.tap();

        verify(item.expanded);
        compare(reply.invoked, 0);
        compare(dismissedSpy.count, 0);
        compare(closeSpy.count, 0);

        item.tap();
        verify(!item.expanded);
    }

    function test_aCardWhoseNotificationIsGoneExpandsWhenTapped() {
        const item = makeCard({ notification: null });

        item.tap();

        verify(item.expanded);
        compare(dismissedSpy.count, 0);
    }

    function test_draggingACardSidewaysPastTheThresholdDismissesIt() {
        const item = makeCard();

        item.swipeOffset = 160;
        item.swipeReleased();

        dismissedSpy.wait(1000);
        compare(dismissedSpy.count, 1);
        compare(closeSpy.count, 0);
    }

    function test_draggingACardToTheLeftPastTheThresholdDismissesItToo() {
        const item = makeCard();

        item.swipeOffset = -160;
        item.swipeReleased();

        dismissedSpy.wait(1000);
        compare(dismissedSpy.count, 1);
    }

    function test_aShorterDragSnapsTheCardBack() {
        const item = makeCard();

        item.swipeOffset = 120;
        item.swipeReleased();

        tryCompare(item, "swipeOffset", 0);
        wait(50);
        compare(dismissedSpy.count, 0);
    }
}
