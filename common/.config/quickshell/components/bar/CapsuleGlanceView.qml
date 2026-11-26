import QtQuick

// The capsule glance as drawn: its glance cards in a row, left to right, in
// the order CapsuleGlance.cards gives them. Each is a glance card, as a
// change's is in CapsuleChangeView.qml: a ring (GlanceRing) round the card's
// icon, its title and, when there is one, a line of text under it. A click
// on a card asks for its bar element's popup, which opens inside the capsule
// in its place.
Item {
    id: root

    // The cards, as CapsuleGlance.cards gives them.
    property var cards: []
    // How card `index` looks, { opacity, scale, slide } (CapsuleMotion.cardLook):
    // as it enters, after the row.
    property var cardLook: index => ({ opacity: 1, scale: 1, slide: 0 })
    // The bar's appearance, for its text size.
    required property var appearance
    // The colorscheme (config/Theme.qml).
    required property var theme
    // The room round the cards, inside the capsule.
    readonly property real padding: 8

    // A card was clicked: `popup`, its bar element's popup.
    signal cardClicked(string popup)

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

                width: Math.max(132, content.implicitWidth + 24)
                height: content.implicitHeight + 16
                radius: 12
                color: cardHover.hovered ? root.theme.surfaceHover : root.theme.surface
                opacity: look.opacity
                scale: look.scale
                transform: Translate { x: card.look.slide }

                HoverHandler {
                    id: cardHover
                }

                Row {
                    id: content

                    anchors.verticalCenter: parent.verticalCenter
                    x: 12
                    spacing: 10

                    Item {
                        anchors.verticalCenter: parent.verticalCenter
                        width: card.ringSize
                        height: card.ringSize

                        GlanceRing {
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
                }

                TapHandler {
                    onTapped: root.cardClicked(card.modelData.popup)
                }
            }
        }
    }
}
