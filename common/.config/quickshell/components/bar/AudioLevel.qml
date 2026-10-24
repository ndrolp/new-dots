import QtQuick
import "../../config" as Config
import "../VolumeText.js" as VolumeText

// What the audio bar element shows: its icon and the volume meter, or the
// percentage when the meter is hidden. The element is as wide as this plus
// its side padding.
Row {
    id: root

    required property var appearance
    property real volume: 0
    property bool muted: true
    property bool meterVisible: true

    spacing: 7

    Config.Theme {
        id: theme
    }

    // The muted and unmuted icons are drawn in a proportional font, so the
    // icon takes the room of the wider one and muting doesn't move the meter.
    TextMetrics {
        id: mutedIcon

        font: icon.font
        text: "󰝟"
    }

    TextMetrics {
        id: unmutedIcon

        font: icon.font
        text: "󰕾"
    }

    Text {
        id: icon

        anchors.verticalCenter: parent.verticalCenter
        width: Math.ceil(Math.max(mutedIcon.advanceWidth, unmutedIcon.advanceWidth))
        horizontalAlignment: Text.AlignHCenter
        text: root.muted ? mutedIcon.text : unmutedIcon.text
        color: theme.blue
        font.pixelSize: root.appearance.textSize
        font.bold: true
    }

    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        visible: root.meterVisible
        width: 34
        height: 4
        radius: 2
        color: theme.surface

        Rectangle {
            width: parent.width * (root.muted ? 0 : root.volume)
            height: parent.height
            radius: parent.radius
            color: theme.blue
        }
    }

    Text {
        anchors.verticalCenter: parent.verticalCenter
        visible: !root.meterVisible
        text: VolumeText.percentage(root.volume)
        color: root.muted ? theme.textMuted : theme.blue
        font.pixelSize: root.appearance.textSize
        font.bold: true
    }
}
