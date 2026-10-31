import QtQuick
import QtTest
import "../components/panels" as Panels
import "../config/Motion.js" as Motion

// The ongoing notifications on top of the control center, in both stages:
// the media card while a player is active, then the `resident` notifications,
// newest first. They take no room while there are none.
// Pointer events don't reach items under qmltestrunner offscreen, so cards
// are driven through their signals.
TestCase {
    name: "ControlCenterOngoing"
    width: 500
    height: 700
    visible: true
    when: windowShown

    QtObject {
        id: barAppearance

        property int radius: 12
        property int textSize: 13
        readonly property var motion: Motion.motion(true)
    }

    // Stands in for services/NotificationHistory.qml.
    Component {
        id: fakeHistory

        QtObject {
            property var items: []
            readonly property var ongoing: items.filter(item => item.resident)

            function remove(id) {
                items = items.filter(item => item.id !== id);
            }
        }
    }

    // Stands in for a Quickshell MprisPlayer.
    Component {
        id: fakePlayer

        QtObject {
            property string identity: "Spotify"
            property string trackTitle: "Song"
            property string trackArtist: "Artist"
            property string trackArtUrl: ""
            property bool isPlaying: true
            property bool canTogglePlaying: true
            property bool canGoNext: true
            property bool canGoPrevious: true
        }
    }

    Component {
        id: ongoingComponent

        Panels.ControlCenterOngoing {
            appearance: barAppearance
            width: 400
        }
    }

    function ongoingEntry(id) {
        return {
            id: id,
            appName: "Syncthing",
            summary: "Syncing " + id,
            body: "",
            notification: null,
            resident: true,
            count: 1,
            unread: false,
            timestamp: Date.now()
        };
    }

    function makeOngoing(items, properties) {
        const history = createTemporaryObject(fakeHistory, this, { items: items });
        return createTemporaryObject(ongoingComponent, this,
            Object.assign({ notificationHistory: history }, properties || {}));
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

    function test_showsTheOngoingNotificationsNewestFirst() {
        const item = makeOngoing([ongoingEntry(2), ongoingEntry(1)]);

        compare(cards(item).map(card => card.entry.summary), ["Syncing 2", "Syncing 1"]);
    }

    function test_theMediaCardSitsAboveTheOngoingNotifications() {
        const player = createTemporaryObject(fakePlayer, this);
        const item = makeOngoing([ongoingEntry(1)], { player: player });
        const media = findAll(item, child => child.objectName === "mediaCard")[0];

        verify(media.visible);
        verify(media.mapToItem(item, 0, 0).y < cards(item)[0].mapToItem(item, 0, 0).y);
    }

    function test_withNothingOngoingItTakesNoRoom() {
        const item = makeOngoing([]);

        compare(item.height, 0);
    }

    function test_dismissingAnOngoingCardRemovesIt() {
        const item = makeOngoing([ongoingEntry(1), ongoingEntry(2)]);

        cards(item)[0].dismissed();

        compare(item.notificationHistory.items.map(entry => entry.id), [2]);
    }

    function test_anOngoingCardIsHighlightedLikeTheNotificationsBelow() {
        const item = makeOngoing([ongoingEntry(1), ongoingEntry(2)], { highlightedIds: [2] });

        compare(cards(item).map(card => card.highlighted), [false, true]);
    }

    function test_aCardAskingToCloseClosesTheControlCenter() {
        const item = makeOngoing([ongoingEntry(1)]);
        let closeRequests = 0;
        item.closeRequested.connect(() => closeRequests++);

        cards(item)[0].closeRequested();

        compare(closeRequests, 1);
    }
}
