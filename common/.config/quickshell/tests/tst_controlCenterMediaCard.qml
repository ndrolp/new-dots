import QtQuick
import QtTest
import "../components/panels" as Panels
import "../components/panels/MediaCard.js" as MediaCard
import "../config/Motion.js" as Motion

// The media card, ongoing on top of the control center in both stages while
// a player is active: its track, artist and the playback controls.
// Pointer events don't reach items under qmltestrunner offscreen, so buttons
// are pressed through their signals.
TestCase {
    name: "ControlCenterMediaCard"
    width: 500
    height: 300
    visible: true
    when: windowShown

    QtObject {
        id: barAppearance

        property int radius: 12
        property int textSize: 13
        readonly property var motion: Motion.motion(true)
    }

    // Stands in for a Quickshell MprisPlayer.
    Component {
        id: fakePlayer

        QtObject {
            property string identity: "Spotify"
            property string trackTitle: "Song"
            property string trackArtist: "Artist"
            property string trackArtUrl: ""
            property bool isPlaying: false
            property bool canTogglePlaying: true
            property bool canGoNext: true
            property bool canGoPrevious: true
            property int toggled: 0
            property int nexts: 0
            property int previouses: 0

            function togglePlaying() {
                toggled++;
                isPlaying = !isPlaying;
            }

            function next() {
                nexts++;
            }

            function previous() {
                previouses++;
            }
        }
    }

    Component {
        id: card

        Panels.ControlCenterMediaCard {
            appearance: barAppearance
            width: 400
        }
    }

    function player(properties) {
        return createTemporaryObject(fakePlayer, this, properties || {});
    }

    function findAll(item, test, found) {
        found = found || [];
        if (test(item))
            found.push(item);
        for (let i = 0; i < item.children.length; i++)
            findAll(item.children[i], test, found);
        return found;
    }

    function find(item, name) {
        return findAll(item, child => child.objectName === name)[0] || null;
    }

    function texts(item) {
        return findAll(item, child => child.visible && typeof child.text === "string").map(child => child.text);
    }

    function test_thePlayingPlayerIsTheActiveOne() {
        const paused = player({ trackTitle: "Paused" });
        const playing = player({ trackTitle: "Playing", isPlaying: true });

        compare(MediaCard.activePlayer([paused, playing]), playing);
    }

    function test_withNothingPlayingAPausedTrackIsStillActive() {
        const idle = player({ trackTitle: "" });
        const paused = player({ trackTitle: "Paused" });

        compare(MediaCard.activePlayer([idle, paused]), paused);
    }

    function test_noPlayerOrOnlyIdleOnesMeansNoActivePlayer() {
        compare(MediaCard.activePlayer([]), null);
        compare(MediaCard.activePlayer([player({ trackTitle: "" })]), null);
    }

    function test_withoutAPlayerTheCardIsHidden() {
        const item = createTemporaryObject(card, this, { player: null });

        verify(!item.visible);
        compare(item.height, 0);
    }

    function test_theCardShowsTheTrackAndArtist() {
        const item = createTemporaryObject(card, this, { player: player() });

        verify(item.visible);
        verify(texts(item).indexOf("Song") !== -1);
        verify(texts(item).indexOf("Artist") !== -1);
    }

    function test_playPauseTogglesThePlayerAndShowsWhatItWillDo() {
        const playing = player({ isPlaying: true });
        const item = createTemporaryObject(card, this, { player: playing });
        const button = find(item, "playPauseButton");

        compare(button.label, "󰏤");
        button.activated();

        compare(playing.toggled, 1);
        compare(button.label, "󰐊");
    }

    function test_nextAndPreviousSkipTracks() {
        const sent = player();
        const item = createTemporaryObject(card, this, { player: sent });

        find(item, "nextButton").activated();
        find(item, "previousButton").activated();

        compare([sent.nexts, sent.previouses], [1, 1]);
    }

    function test_aControlThePlayerDoesNotSupportIsDisabled() {
        const item = createTemporaryObject(card, this, { player: player({ canGoNext: false }) });

        verify(!find(item, "nextButton").interactive);
        verify(find(item, "previousButton").interactive);
    }
}
