import Quickshell.Widgets
import QtQuick
import QtQuick.Effects
import "../../config" as Config
import "." as Panels
import "../StatusText.js" as StatusText

// The media popup inside a capsule: the art on the left, rounded, with a
// soft glow behind it; a bold title with the artist under it; a scrubbable
// progress bar with the elapsed and total time; previous, play/pause and
// next. One colour quantized from the art (MediaArtTint.qml) tints the
// progress bar, the play button and the glow; with no art it is the accent.
// The capsule's background stays the profile's.
Item {
    id: root

    required property var appearance
    // The media popup it shows (MediaPopup): its `player` and seeking.
    required property var media

    readonly property var player: media.player
    readonly property real artSize: 88
    readonly property bool artShown: artImage.status === Image.Ready
    readonly property color tint: artTint.tint
    readonly property color onTint: artTint.onTint

    implicitHeight: Math.max(artSize, info.implicitHeight)
    height: implicitHeight

    Config.Theme {
        id: theme
    }

    // The one colour from the art, and what reads on it.
    Panels.MediaArtTint {
        id: artTint

        artUrl: root.player ? root.player.trackArtUrl : ""
        artShown: root.artShown
        theme: theme
    }

    // The soft glow behind the art: a blurred halo of the tint round it.
    Rectangle {
        anchors.fill: art
        radius: art.radius
        color: root.tint
        visible: root.player !== null
        opacity: 0.85

        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: root.tint
            shadowBlur: 1
            shadowScale: 1.06
            shadowOpacity: 0.7
        }

        Behavior on color {
            ColorAnimation { duration: root.appearance.motion.medium }
        }
    }

    ClippingRectangle {
        id: art

        anchors.verticalCenter: parent.verticalCenter
        width: root.artSize
        height: root.artSize
        radius: Math.max(10, root.appearance.radius)
        color: theme.backgroundSecondary

        Image {
            id: artImage

            anchors.fill: parent
            source: root.player ? root.player.trackArtUrl : ""
            sourceSize.width: root.artSize * 2
            sourceSize.height: root.artSize * 2
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
        }

        Panels.ShellText {
            anchors.centerIn: parent
            visible: !root.artShown
            text: "󰎈"
            color: theme.textMuted
            font.pixelSize: 30
        }
    }

    Column {
        id: info

        anchors.left: art.right
        anchors.leftMargin: 16
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        spacing: 2

        PopupTitle {
            appearance: root.appearance
            width: parent.width
            text: root.player ? (root.player.trackTitle || root.player.identity) : "Nothing playing"
        }

        Panels.ShellText {
            width: parent.width
            visible: text !== ""
            text: root.player ? root.player.trackArtist : ""
            color: theme.textMuted
            elide: Text.ElideRight
            font.pixelSize: root.appearance.textSize - 1
        }

        Item {
            width: 1
            height: 4
        }

        Column {
            width: parent.width
            visible: !!root.player && root.player.lengthSupported
            spacing: 0

            MediaSeekBar {
                appearance: root.appearance
                media: root.media
                width: parent.width
                fillColor: root.tint
            }

            Item {
                width: parent.width
                height: elapsed.implicitHeight

                PopupLabel {
                    id: elapsed

                    appearance: root.appearance
                    anchors.left: parent.left
                    text: StatusText.duration(root.media.shownPosition)
                }

                PopupLabel {
                    appearance: root.appearance
                    anchors.right: parent.right
                    text: StatusText.duration(root.player ? root.player.length : 0)
                }
            }
        }

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 10

            PopupButton {
                appearance: root.appearance
                anchors.verticalCenter: parent.verticalCenter
                width: 32
                height: 32
                label: "󰒮"
                labelSize: 16
                interactive: !!root.player && root.player.canGoPrevious
                onActivated: root.player.previous()
            }

            // Play/pause: a round button filled with the tint.
            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: 38
                height: 38
                radius: width / 2
                color: playHover.hovered && playTap.enabled ? Qt.lighter(root.tint, 1.15) : root.tint
                opacity: playTap.enabled ? 1 : 0.5

                Behavior on color {
                    ColorAnimation { duration: root.appearance.motion.short }
                }

                Panels.ShellText {
                    anchors.centerIn: parent
                    text: root.player && root.player.isPlaying ? "󰏤" : "󰐊"
                    color: root.onTint
                    font.pixelSize: 20
                }

                HoverHandler {
                    id: playHover

                    cursorShape: playTap.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                }

                TapHandler {
                    id: playTap

                    enabled: !!root.player && root.player.canTogglePlaying
                    onTapped: root.player.togglePlaying()
                }
            }

            PopupButton {
                appearance: root.appearance
                anchors.verticalCenter: parent.verticalCenter
                width: 32
                height: 32
                label: "󰒭"
                labelSize: 16
                interactive: !!root.player && root.player.canGoNext
                onActivated: root.player.next()
            }
        }
    }
}
