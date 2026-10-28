import Quickshell
import Quickshell.Services.Mpris
import QtQuick
import "../../config" as Config
import "." as Panels
import "../StatusText.js" as StatusText

// The media popup: what plays now, how far along it is and the playback controls.
// It follows the player that is playing, or the first one when none is.
BarPopup {
    id: root

    property var player: null
    property real mediaPosition: 0
    property string mediaTrackKey: ""

    function activePlayer() {
        const players = Mpris.players.values;

        for (let index = 0; index < players.length; index++) {
            if (players[index].isPlaying)
                return players[index];
        }

        return players.length > 0 ? players[0] : null;
    }

    function updatePlayer() {
        const nextPlayer = activePlayer();
        const trackKey = nextPlayer
            ? nextPlayer.identity + "\u0000" + nextPlayer.trackTitle + "\u0000" + nextPlayer.length : "";

        if (nextPlayer !== player || trackKey !== mediaTrackKey) {
            player = nextPlayer;
            mediaTrackKey = trackKey;
            mediaPosition = player ? player.position : 0;
        } else if (player) {
            mediaPosition = player.isPlaying
                ? Math.min(player.length, mediaPosition + 1) : player.position;
        }
    }

    Component.onCompleted: updatePlayer()

    popup: "media"
    implicitWidth: 440

    Config.Theme {
        id: theme
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: root.updatePlayer()
    }

    Row {
        width: parent.width
        spacing: 12

        Rectangle {
            id: mediaArt

            width: 112
            height: 112
            radius: root.appearance.radius
            color: theme.backgroundSecondary
            clip: true

            Image {
                id: mediaArtImage

                anchors.fill: parent
                source: root.player ? root.player.trackArtUrl : ""
                fillMode: Image.PreserveAspectCrop
            }

            Panels.Text {
                anchors.centerIn: parent
                visible: mediaArtImage.status !== Image.Ready
                text: "󰎈"
                color: theme.textMuted
                font.pixelSize: 32
            }
        }

        Column {
            width: parent.width - mediaArt.width - parent.spacing
            anchors.verticalCenter: parent.verticalCenter
            spacing: 4

            PopupTitle {
                appearance: root.appearance
                width: parent.width
                text: root.player
                    ? (root.player.trackTitle || root.player.identity)
                    : "Nothing playing"
            }

            Panels.Text {
                width: parent.width
                visible: text !== ""
                text: root.player ? root.player.trackArtist : ""
                color: theme.textMuted
                elide: Text.ElideRight
                font.pixelSize: root.appearance.textSize - 1
            }

            PopupLabel {
                appearance: root.appearance
                width: parent.width
                visible: !!root.player && root.player.identity !== ""
                text: root.player ? root.player.identity : ""
            }

            Item {
                width: 1
                height: 4
            }

            Column {
                width: parent.width
                visible: !!root.player && root.player.lengthSupported
                spacing: 4

                PopupProgress {
                    appearance: root.appearance
                    width: parent.width
                    fraction: root.player && root.player.length > 0
                        ? root.mediaPosition / root.player.length : 0
                }

                Item {
                    width: parent.width
                    height: currentTime.implicitHeight

                    PopupLabel {
                        id: currentTime

                        appearance: root.appearance
                        anchors.left: parent.left
                        text: StatusText.duration(root.mediaPosition)
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
                spacing: 4

                PopupButton {
                    appearance: root.appearance
                    width: 32
                    height: 32
                    label: "󰒮"
                    labelSize: 16
                    interactive: !!root.player && root.player.canGoPrevious
                    onActivated: root.player.previous()
                }

                PopupButton {
                    appearance: root.appearance
                    width: 36
                    height: 32
                    label: root.player && root.player.isPlaying ? "󰏤" : "󰐊"
                    labelColor: theme.accent
                    labelSize: 20
                    interactive: !!root.player && root.player.canTogglePlaying
                    onActivated: root.player.togglePlaying()
                }

                PopupButton {
                    appearance: root.appearance
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
}
