import QtQuick
import "../../config" as Config
import "../Clamp.js" as Clamp

// The media popup's progress bar. When the player can seek, clicking it, or
// dragging along it and letting go, moves playback there; while dragged, the
// bar follows the pointer. Taller than the bar it draws, so it is easy to hit.
Item {
    id: seekBar

    required property var appearance
    // The media popup it seeks in (MediaPopup): its `player`, whether it is
    // `seekable`, its `shownPosition`, `dragFraction` and `seekTo`.
    required property var media
    property color fillColor: theme.accent
    // How thick the bar is at rest; it grows by 2 while hovered or dragged.
    property real thickness: 4

    readonly property bool active: seekArea.containsMouse || media.dragFraction >= 0

    height: 14

    Config.Theme {
        id: theme
    }

    PopupProgress {
        id: progress

        appearance: seekBar.appearance
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: seekBar.active && seekBar.media.seekable ? seekBar.thickness + 2 : seekBar.thickness
        radius: height / 2
        fillColor: seekBar.fillColor
        fraction: seekBar.media.player && seekBar.media.player.length > 0
            ? seekBar.media.shownPosition / seekBar.media.player.length : 0

        Behavior on height {
            NumberAnimation { duration: seekBar.appearance.motion.short }
        }
    }

    Rectangle {
        visible: seekBar.active && seekBar.media.seekable
        width: 12
        height: 12
        radius: 6
        anchors.verticalCenter: parent.verticalCenter
        x: Math.max(0, Math.min(parent.width - width,
            parent.width * progress.fraction - width / 2))
        color: seekBar.fillColor
    }

    MouseArea {
        id: seekArea

        function fractionAt(x) {
            return Clamp.unit(x / width);
        }

        anchors.fill: parent
        enabled: seekBar.media.seekable
        hoverEnabled: true
        cursorShape: seekBar.media.seekable ? Qt.PointingHandCursor : Qt.ArrowCursor
        preventStealing: true

        onPressed: mouse => seekBar.media.dragFraction = fractionAt(mouse.x)
        onPositionChanged: mouse => {
            if (pressed)
                seekBar.media.dragFraction = fractionAt(mouse.x);
        }
        onReleased: mouse => {
            const fraction = fractionAt(mouse.x);
            seekBar.media.dragFraction = -1;
            seekBar.media.seekTo(fraction * seekBar.media.player.length);
        }
        onCanceled: seekBar.media.dragFraction = -1
    }
}
