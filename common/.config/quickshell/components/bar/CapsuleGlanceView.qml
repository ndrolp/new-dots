import QtQuick
import QtQuick.Effects
import ".." as Components

// The capsule glance as drawn: its glance cards in a row, left to right, in
// the order CapsuleGlance.cards gives them. Each is drawn as a change's ring
// card is in CapsuleChangeView.qml: a level ring (LevelRing) round the card's
// icon, its title and, when there is one, a line of text under it. The media
// card shows the small rounded cover in the ring's place and a play/pause
// button after its title and artist, tinted with the colour from the art
// (`mediaTint`), as the capsule's media popup is. A click on a card asks for
// its bar element's popup, which opens inside the capsule in its place;
// play/pause only plays or pauses, and scrolling over the media card changes
// track, at most one per notch or touchpad gesture, as on the Media element.
Item {
    id: root

    // The cards, as CapsuleGlance.cards gives them.
    property var cards: []
    // How card `index` looks, { opacity, scale, slide } (CapsuleMotion.cardLook):
    // as it enters, after the row.
    property var cardLook: index => ({ opacity: 1, scale: 1, slide: 0 })
    // The one colour from the media art (MediaCard.artTint), and what reads
    // on it (MediaCard.onTint): the media card's tint and its play/pause
    // button's glyph.
    property color mediaTint: theme.accent
    property color mediaOnTint: theme.background
    // The bar's appearance, for its text size.
    required property var appearance
    // The colorscheme (config/Theme.qml).
    required property var theme
    // The room round the cards, inside the capsule.
    readonly property real padding: 8

    // A card was clicked: `popup`, its bar element's popup.
    signal cardClicked(string popup)
    // The media card's play/pause was clicked.
    signal playPauseClicked()
    // A scroll over the media card stepped (components/WheelSteps.js):
    // forward (1) to the next track, back (-1) to the previous one.
    signal mediaStepped(int step)

    // The cards as drawn, left to right.
    function cardItems() {
        const items = [];
        for (let index = 0; index < cardRepeater.count; index++)
            items.push(cardRepeater.itemAt(index));
        return items;
    }

    implicitWidth: row.implicitWidth + padding * 2
    implicitHeight: row.implicitHeight + padding * 2

    Row {
        id: row

        x: root.padding
        y: root.padding
        spacing: 8

        Repeater {
            id: cardRepeater

            model: root.cards

            delegate: Rectangle {
                id: card

                required property var modelData
                required property int index
                readonly property var look: root.cardLook(index)
                readonly property real ringSize: root.appearance.textSize * 2 + 8
                // Whether it is the media card.
                readonly property bool media: modelData.id === "media"
                // Its parts, for tests: the ring, the media card's cover and
                // play/pause button, and the glyph that button shows.
                readonly property Item ringItem: ring
                readonly property Item coverItem: cover
                readonly property Item playButton: play
                readonly property string playGlyph: modelData.playing === true ? "󰏤" : "󰐊"
                // The surface, under a wash of the art's tint on the media card.
                readonly property color surface: cardHover.hovered ? root.theme.surfaceHover : root.theme.surface

                width: Math.max(132, content.implicitWidth + 24)
                height: content.implicitHeight + 16
                radius: 12
                color: media
                    ? Qt.tint(surface, Qt.rgba(root.mediaTint.r, root.mediaTint.g, root.mediaTint.b, 0.22))
                    : surface
                RowLook { target: card; look: card.look }

                HoverHandler {
                    id: cardHover
                }

                Row {
                    id: content

                    anchors.verticalCenter: parent.verticalCenter
                    x: 12
                    spacing: 10

                    Item {
                        id: ring

                        anchors.verticalCenter: parent.verticalCenter
                        visible: !card.media
                        width: card.ringSize
                        height: card.ringSize

                        LevelRing {
                            anchors.fill: parent
                            level: card.modelData.ring
                            trackColor: root.theme.backgroundSecondary
                            levelColor: root.theme.accent
                        }

                        ShellText {
                            anchors.centerIn: parent
                            text: card.modelData.icon
                            color: root.theme.text
                            font.pixelSize: root.appearance.textSize + 2
                            font.bold: true
                        }
                    }

                    // The cover, rounded, as large as the ring; the media
                    // glyph while there is no art.
                    Rectangle {
                        id: cover

                        anchors.verticalCenter: parent.verticalCenter
                        visible: card.media
                        width: card.ringSize
                        height: card.ringSize
                        radius: 8
                        color: root.theme.backgroundSecondary

                        Image {
                            id: coverArt

                            anchors.fill: parent
                            visible: false
                            source: card.media ? card.modelData.art : ""
                            sourceSize.width: card.ringSize * 2
                            sourceSize.height: card.ringSize * 2
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                        }

                        Rectangle {
                            id: coverMask

                            anchors.fill: parent
                            radius: cover.radius
                            visible: false
                            layer.enabled: true
                        }

                        MultiEffect {
                            anchors.fill: parent
                            visible: coverArt.status === Image.Ready
                            source: coverArt
                            maskEnabled: true
                            maskSource: coverMask
                        }

                        ShellText {
                            anchors.centerIn: parent
                            visible: coverArt.status !== Image.Ready
                            text: card.modelData.icon
                            color: root.theme.textMuted
                            font.pixelSize: root.appearance.textSize + 2
                        }
                    }

                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 2

                        ShellText {
                            width: Math.min(implicitWidth, 160)
                            text: card.modelData.title
                            color: root.theme.text
                            elide: Text.ElideRight
                            font.pixelSize: root.appearance.textSize
                            font.bold: true
                        }

                        ShellText {
                            visible: card.modelData.text !== ""
                            width: Math.min(implicitWidth, 160)
                            text: card.modelData.text
                            color: root.theme.textMuted
                            elide: Text.ElideRight
                            font.pixelSize: root.appearance.textSize - 1
                        }
                    }

                    // Play/pause: a round button filled with the tint, which
                    // only plays or pauses.
                    Rectangle {
                        id: play

                        anchors.verticalCenter: parent.verticalCenter
                        visible: card.media
                        width: card.ringSize - 4
                        height: width
                        radius: width / 2
                        color: playArea.containsMouse ? Qt.lighter(root.mediaTint, 1.15) : root.mediaTint

                        ShellText {
                            anchors.centerIn: parent
                            text: card.playGlyph
                            color: root.mediaOnTint
                            font.pixelSize: root.appearance.textSize + 3
                        }

                        MouseArea {
                            id: playArea

                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.playPauseClicked()
                        }
                    }
                }

                TapHandler {
                    onTapped: root.cardClicked(card.modelData.popup)
                }

                // Scrolling over the media card changes track.
                Components.WheelStepHandler {
                    enabled: card.media
                    onStepped: step => root.mediaStepped(step)
                }
            }
        }
    }
}
