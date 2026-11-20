import Quickshell
import Quickshell.Services.Mpris
import QtQuick
import "../../config" as Config
import "." as Panels
import "../StatusText.js" as StatusText

// The media popup: what plays now, how far along it is and the playback controls.
// It follows the player that is playing, or the first one when none is. When
// the player can seek, clicking the progress bar, or dragging along it and
// letting go, moves playback there. With more than one player, "N more
// players" expands a list of the others; choosing one makes the popup follow
// it until the popup closes.
BarPopup {
    id: root

    property var player: null
    property real mediaPosition: 0
    property string mediaTrackKey: ""
    // While the progress bar is dragged, the fraction under the pointer; -1
    // otherwise. The bar and the time follow it, and playback moves on release.
    property real dragFraction: -1
    readonly property bool seekable: !!player && player.canSeek && player.length > 0
    readonly property real shownPosition: dragFraction >= 0 && player
        ? dragFraction * player.length : mediaPosition

    // Moves playback to `target` seconds. A player that can't take a position
    // may still seek by an offset (Mpris docs).
    function seekTo(target) {
        if (!seekable)
            return;

        const clamped = Math.max(0, Math.min(player.length, target));
        if (player.positionSupported)
            player.position = clamped;
        else
            player.seek(clamped - mediaPosition);
        mediaPosition = clamped;
    }

    // The player chosen from the list, followed until the popup closes; null
    // follows the one that is playing.
    property var chosenPlayer: null
    // Whether the list of the other players is expanded.
    property bool showingPlayers: false
    readonly property var otherPlayers: Mpris.players.values.filter(candidate => candidate !== player)

    function choosePlayer(chosen) {
        chosenPlayer = chosen;
        showingPlayers = false;
        updatePlayer();
    }

    onOpenChanged: {
        if (open)
            return;
        chosenPlayer = null;
        showingPlayers = false;
        updatePlayer();
    }

    function activePlayer() {
        const players = Mpris.players.values;
        if (chosenPlayer && players.indexOf(chosenPlayer) !== -1)
            return chosenPlayer;

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
    popupWidth: 440

    Config.Theme {
        id: theme
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: root.updatePlayer()
    }

    Column {
        width: parent.width
        spacing: 10

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

                Panels.ShellText {
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

                Panels.ShellText {
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

                    Item {
                        id: seekBar

                        readonly property bool active: seekArea.containsMouse || root.dragFraction >= 0

                        width: parent.width
                        // Taller than the bar, so it is easy to hit.
                        height: 14

                        PopupProgress {
                            id: progress

                            appearance: root.appearance
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width
                            height: seekBar.active && root.seekable ? 6 : 4
                            radius: height / 2
                            fraction: root.player && root.player.length > 0
                                ? root.shownPosition / root.player.length : 0

                            Behavior on height {
                                NumberAnimation { duration: root.appearance.motion.short }
                            }
                        }

                        Rectangle {
                            visible: seekBar.active && root.seekable
                            width: 12
                            height: 12
                            radius: 6
                            anchors.verticalCenter: parent.verticalCenter
                            x: Math.max(0, Math.min(parent.width - width,
                                parent.width * progress.fraction - width / 2))
                            color: theme.accent
                        }

                        MouseArea {
                            id: seekArea

                            function fractionAt(x) {
                                return Math.max(0, Math.min(1, x / width));
                            }

                            anchors.fill: parent
                            enabled: root.seekable
                            hoverEnabled: true
                            cursorShape: root.seekable ? Qt.PointingHandCursor : Qt.ArrowCursor
                            preventStealing: true

                            onPressed: mouse => root.dragFraction = fractionAt(mouse.x)
                            onPositionChanged: mouse => {
                                if (pressed)
                                    root.dragFraction = fractionAt(mouse.x);
                            }
                            onReleased: mouse => {
                                const fraction = fractionAt(mouse.x);
                                root.dragFraction = -1;
                                root.seekTo(fraction * root.player.length);
                            }
                            onCanceled: root.dragFraction = -1
                        }
                    }

                    Item {
                        width: parent.width
                        height: currentTime.implicitHeight

                        PopupLabel {
                            id: currentTime

                            appearance: root.appearance
                            anchors.left: parent.left
                            text: StatusText.duration(root.shownPosition)
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

        // The other players, behind "N more players".
        PopupButton {
            appearance: root.appearance
            width: parent.width
            height: 26
            visible: root.otherPlayers.length > 0
            label: (root.showingPlayers ? "󰅃  " : "󰅀  ") + root.otherPlayers.length
                + (root.otherPlayers.length === 1 ? " more player" : " more players")
            labelColor: theme.textMuted
            labelSize: root.appearance.textSize - 2
            onActivated: root.showingPlayers = !root.showingPlayers
        }

        Column {
            width: parent.width
            visible: root.showingPlayers && root.otherPlayers.length > 0
            spacing: 4

            Repeater {
                model: root.showingPlayers ? root.otherPlayers : []

                delegate: Rectangle {
                    id: playerRow

                    required property var modelData

                    width: parent.width
                    height: 48
                    radius: root.appearance.radius
                    color: rowHover.hovered ? theme.surfaceHover : theme.backgroundSecondary

                    HoverHandler {
                        id: rowHover
                    }

                    TapHandler {
                        // A tap on its play button is the button's.
                        onTapped: eventPoint => {
                            const point = playerRow.mapToItem(rowToggle,
                                eventPoint.position.x, eventPoint.position.y);
                            if (!rowToggle.contains(point))
                                root.choosePlayer(playerRow.modelData);
                        }
                    }

                    Rectangle {
                        id: rowArt

                        x: 8
                        anchors.verticalCenter: parent.verticalCenter
                        width: 34
                        height: 34
                        radius: Math.max(4, root.appearance.radius / 2)
                        color: theme.surface
                        clip: true

                        Image {
                            id: rowArtImage

                            anchors.fill: parent
                            source: playerRow.modelData.trackArtUrl || ""
                            sourceSize.width: 68
                            sourceSize.height: 68
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                        }

                        Panels.ShellText {
                            anchors.centerIn: parent
                            visible: rowArtImage.status !== Image.Ready
                            text: "󰎈"
                            color: theme.textMuted
                            font.pixelSize: 16
                        }
                    }

                    Column {
                        anchors.left: rowArt.right
                        anchors.leftMargin: 10
                        anchors.right: rowToggle.left
                        anchors.rightMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 2

                        Panels.ShellText {
                            width: parent.width
                            text: playerRow.modelData.identity || "Player"
                            color: theme.text
                            elide: Text.ElideRight
                            font.bold: true
                            font.pixelSize: root.appearance.textSize - 1
                        }

                        Panels.ShellText {
                            width: parent.width
                            visible: text !== ""
                            text: [playerRow.modelData.trackTitle, playerRow.modelData.trackArtist]
                                .filter(part => !!part).join("  ·  ")
                            color: theme.textMuted
                            elide: Text.ElideRight
                            font.pixelSize: root.appearance.textSize - 2
                        }
                    }

                    PopupButton {
                        id: rowToggle

                        appearance: root.appearance
                        anchors.right: parent.right
                        anchors.rightMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        width: 30
                        height: 30
                        label: playerRow.modelData.isPlaying ? "󰏤" : "󰐊"
                        labelColor: theme.accent
                        labelSize: 16
                        interactive: playerRow.modelData.canTogglePlaying
                        onActivated: playerRow.modelData.togglePlaying()
                    }
                }
            }
        }
    }
}
