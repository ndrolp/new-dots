import QtQuick
import QtTest
import "../components/bar"
import "../config/Motion.js" as Motion

// The capsule glance as drawn: one glance card per card, left to right, each
// taking its own look as it enters, and a click on one asking for its popup.
TestCase {
    name: "CapsuleGlanceView"
    width: 600
    height: 200
    visible: true
    when: windowShown

    readonly property var cards: [
        { id: "battery", element: "battery", popup: "battery", icon: "B", ring: 0.84, title: "84%",
            text: "3 h 20 m left" },
        { id: "network", element: "network", popup: "network", icon: "W", ring: 0.72, title: "Home",
            text: "" }
    ]

    Component {
        id: viewComponent

        CapsuleGlanceView {
            theme: ({
                accent: "#ff00ff",
                text: "#ffffff",
                textMuted: "#808080",
                surface: "#101010",
                surfaceHover: "#303030",
                background: "#000000",
                backgroundSecondary: "#202020"
            })
            appearance: ({ textSize: 13, motion: Motion.motion(false) })
        }
    }

    SignalSpy {
        id: clicks

        signalName: "cardClicked"
    }

    function view(properties) {
        const shown = createTemporaryObject(viewComponent, this, properties);
        clicks.clear();
        clicks.target = shown;
        return shown;
    }

    // One card per card, left to right.
    function test_itShowsACardPerCard() {
        const shown = view({ cards: cards });

        compare(shown.cardItems().length, 2);
        verify(shown.cardItems()[0].x < shown.cardItems()[1].x);
        verify(shown.implicitWidth > 0);
        verify(shown.implicitHeight > 0);
    }

    // A click on a card asks for its bar element's popup.
    function test_clickingACardAsksForItsPopup() {
        const shown = view({ cards: cards });
        const card = shown.cardItems()[1];

        mouseClick(card, card.width / 2, card.height / 2);

        compare(clicks.count, 1);
        compare(clicks.signalArguments[0][0], "network");
    }

    readonly property var mediaCard: ({ id: "media", element: "media", popup: "media", icon: "M", ring: 0,
        title: "Teardrop", text: "Massive Attack", art: "", playing: true })

    SignalSpy {
        id: toggles

        signalName: "playPauseClicked"
    }

    SignalSpy {
        id: steps

        signalName: "mediaStepped"
    }

    function mediaView() {
        const shown = view({ cards: [mediaCard].concat(cards), mediaTint: "#3366cc", mediaOnTint: "#000000" });
        toggles.clear();
        toggles.target = shown;
        steps.clear();
        steps.target = shown;
        return shown;
    }

    // The media card: the cover, the title over the artist and a play/pause
    // button filled with the tint from the art, pause while it plays.
    function test_theMediaCardShowsTheTrack() {
        const shown = mediaView();
        const media = shown.cardItems()[0];

        verify(media.coverItem.visible);
        verify(!media.ringItem.visible);
        verify(media.playButton.visible);
        compare(media.playButton.color, Qt.color("#3366cc"));
        compare(media.playGlyph, "󰏤");
        verify(!shown.cardItems()[1].playButton.visible);
    }

    // Play/pause only plays or pauses: it opens no popup.
    function test_playPauseOnlyToggles() {
        const shown = mediaView();
        const button = shown.cardItems()[0].playButton;

        mouseClick(button, button.width / 2, button.height / 2);

        compare(toggles.count, 1);
        compare(clicks.count, 0);
    }

    // Clicking the rest of the media card opens the media popup.
    function test_clickingTheMediaCardOpensItsPopup() {
        const shown = mediaView();
        const media = shown.cardItems()[0];

        mouseClick(media, 4, media.height / 2);

        compare(clicks.count, 1);
        compare(clicks.signalArguments[0][0], "media");
        compare(toggles.count, 0);
    }

    // Scrolling over the media card changes track: down forward, up back.
    function test_scrollingTheMediaCardChangesTrack() {
        const shown = mediaView();
        const media = shown.cardItems()[0];

        mouseWheel(media, 4, media.height / 2, 0, -120);
        wait(400);
        mouseWheel(media, 4, media.height / 2, 0, 120);

        compare(steps.count, 2);
        compare(steps.signalArguments[0][0], 1);
        compare(steps.signalArguments[1][0], -1);
    }

    // Scrolling over another card changes no track.
    function test_scrollingAnotherCardChangesNothing() {
        const shown = mediaView();
        const battery = shown.cardItems()[1];

        mouseWheel(battery, 4, battery.height / 2, 0, -120);

        compare(steps.count, 0);
    }

    // Each card takes the look `cardLook` gives it, by its index.
    function test_eachCardTakesItsLook() {
        const shown = view({
            cards: cards,
            cardLook: index => ({ opacity: index === 0 ? 1 : 0.25, scale: 1, slide: -3 })
        });

        compare(shown.cardItems()[0].opacity, 1);
        compare(shown.cardItems()[1].opacity, 0.25);
    }
}
