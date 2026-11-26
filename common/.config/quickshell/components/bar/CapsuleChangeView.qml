import QtQuick
import "../panels" as Panels
import "../panels/OsdChange.js" as OsdChange

// What a capsule shows instead of the OSD while a change shows, in one row
// as deep as the capsule, by its card (OsdChange.capsuleLook):
// - volume and brightness: an icon whose glyph follows the level and bounces
//   slightly on each change, a wide fill bar and the percentage;
// - battery and Bluetooth: a glance card, the icon, one line of text and a
//   small ring of the battery level when there is one;
// - anything else: the OSD's icon and label.
Item {
    id: root

    // The change, as OsdChange.js describes it, or null.
    property var change: null
    // The bar's appearance, for its text size and motion.
    required property var appearance
    // The colorscheme (config/Theme.qml).
    required property var theme
    // How it shows in the capsule (OsdChange.capsuleLook), or null without a
    // change.
    readonly property var look: change ? OsdChange.capsuleLook(change) : null
    // The OSD's look, for the icon and label of a "row" card.
    readonly property var display: change ? OsdChange.display(change) : null
    readonly property string card: look ? look.card : ""
    readonly property string icon: !look ? "" : card === "row" ? display.icon : look.icon
    readonly property color toneColor: OsdChange.toneColor(
        !look ? "muted" : card === "row" ? display.tone : look.tone, theme)
    readonly property bool highlighted: !look ? false
        : card === "row" ? display.highlighted : card === "glance" && look.highlighted
    // Whether the glance card's level ring shows.
    readonly property bool ringShown: card === "glance" && look.ring !== null
    // The icon's scale, bouncing slightly on each volume or brightness change.
    property real iconScale: 1

    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight
    visible: look !== null

    onChangeChanged: {
        if (card !== "level" || !appearance.motion || appearance.motion.short <= 0)
            return;
        bounce.restart();
    }

    SequentialAnimation {
        id: bounce

        NumberAnimation {
            target: root
            property: "iconScale"
            to: 1.18
            duration: root.appearance.motion ? root.appearance.motion.brief : 0
            easing.type: Easing.OutQuad
        }

        NumberAnimation {
            target: root
            property: "iconScale"
            to: 1
            duration: root.appearance.motion ? root.appearance.motion.medium : 0
            easing.type: Easing.OutBack
        }
    }

    Row {
        id: row

        anchors.verticalCenter: parent.verticalCenter
        spacing: 8

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: root.appearance.textSize + 10
            height: width
            radius: width / 2
            color: root.highlighted ? root.theme.accent : "transparent"

            ShellText {
                anchors.centerIn: parent
                text: root.icon
                color: root.highlighted ? root.theme.background : root.toneColor
                scale: root.iconScale
                font.pixelSize: root.appearance.textSize + 2
                font.bold: true
            }
        }

        ShellText {
            anchors.verticalCenter: parent.verticalCenter
            visible: root.card !== "level"
            width: Math.min(implicitWidth, 240)
            text: !root.look ? "" : root.card === "glance" ? root.look.text : root.display.label
            color: root.theme.text
            elide: Text.ElideRight
            font.pixelSize: root.appearance.textSize
            font.bold: true
        }

        Panels.ChangeLevel {
            anchors.verticalCenter: parent.verticalCenter
            visible: root.card === "level"
            barWidth: 200
            level: root.card === "level" ? root.look.level : 0
            toneColor: root.toneColor
            appearance: root.appearance
            theme: root.theme
        }

        // The glance card's battery ring.
        GlanceRing {
            anchors.verticalCenter: parent.verticalCenter
            visible: root.ringShown
            width: root.appearance.textSize + 4
            height: width
            level: root.ringShown ? root.look.ring : 0
            trackColor: root.theme.backgroundSecondary
            levelColor: root.toneColor
        }
    }
}
