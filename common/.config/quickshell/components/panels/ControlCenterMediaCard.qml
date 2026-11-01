import QtQuick
import "../../config" as Config
import "." as Panels

// The media card: an ongoing notification on top of the control center, in
// both stages, while a player is active (MediaCard.activePlayer); it is
// drawn by ControlCenterOngoing. It shows the track,
// the artist and the playback controls; with no `player` it is hidden and
// takes no room. `player` is a Quickshell MprisPlayer.
Rectangle {
    id: root

    required property var appearance
    property var player: null

    objectName: "mediaCard"
    visible: !!player
    height: visible ? 64 : 0
    radius: appearance.radius
    color: theme.backgroundSecondary
    border.width: 1
    border.color: Qt.rgba(theme.border.r, theme.border.g, theme.border.b, 0.5)

    Config.Theme {
        id: theme
    }

    Rectangle {
        id: art

        x: 10
        anchors.verticalCenter: parent.verticalCenter
        width: 44
        height: 44
        radius: Math.max(4, root.appearance.radius - 4)
        color: Qt.rgba(theme.accent.r, theme.accent.g, theme.accent.b, 0.16)
        clip: true

        Image {
            id: artImage

            anchors.fill: parent
            source: root.player ? root.player.trackArtUrl : ""
            sourceSize.width: 88
            sourceSize.height: 88
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
        }

        Panels.Text {
            anchors.centerIn: parent
            visible: artImage.status !== Image.Ready
            text: "󰎈"
            color: theme.accent
            font.pixelSize: 20
        }
    }

    Column {
        anchors.left: art.right
        anchors.leftMargin: 10
        anchors.right: controls.left
        anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        spacing: 1

        PopupTitle {
            width: parent.width
            appearance: root.appearance
            text: root.player ? (root.player.trackTitle || root.player.identity) : ""
            font.pixelSize: root.appearance.textSize
        }

        PopupLabel {
            width: parent.width
            visible: text !== ""
            appearance: root.appearance
            text: root.player ? root.player.trackArtist : ""
        }
    }

    Row {
        id: controls

        anchors.right: parent.right
        anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        spacing: 2

        PopupButton {
            objectName: "previousButton"
            appearance: root.appearance
            width: 30
            height: 30
            label: "󰒮"
            labelSize: 15
            interactive: !!root.player && root.player.canGoPrevious
            onActivated: root.player.previous()
        }

        PopupButton {
            objectName: "playPauseButton"
            appearance: root.appearance
            width: 34
            height: 30
            label: root.player && root.player.isPlaying ? "󰏤" : "󰐊"
            labelColor: theme.accent
            labelSize: 19
            interactive: !!root.player && root.player.canTogglePlaying
            onActivated: root.player.togglePlaying()
        }

        PopupButton {
            objectName: "nextButton"
            appearance: root.appearance
            width: 30
            height: 30
            label: "󰒭"
            labelSize: 15
            interactive: !!root.player && root.player.canGoNext
            onActivated: root.player.next()
        }
    }
}
