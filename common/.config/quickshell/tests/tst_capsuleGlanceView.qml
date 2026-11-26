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
