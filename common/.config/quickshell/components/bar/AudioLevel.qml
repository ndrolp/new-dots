import QtQuick
import "../../config" as Config
import "../VolumeText.js" as VolumeText
import "BarLayout.js" as BarLayout

// What the audio bar element shows: its icon and the volume meter, or the
// percentage when the meter is hidden, underneath the icon on a side bar. The
// element is as long as this plus its padding.
ElementStack {
    id: root

    property real volume: 0
    property bool muted: true
    property bool meterVisible: true

    spacing: sideBar ? 3 : 7

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

    ShellText {
        id: icon

        width: Math.ceil(Math.max(mutedIcon.advanceWidth, unmutedIcon.advanceWidth))
        horizontalAlignment: Text.AlignHCenter
        text: root.muted ? mutedIcon.text : unmutedIcon.text
        color: theme.blue
        font.pixelSize: root.appearance.iconSize
        font.bold: true
    }

    // As high as the icon beside it, so the meter stays centred on the pixel
    // an anchor puts it on. Across a side bar it fits the bar element.
    Item {
        visible: root.meterVisible
        width: root.sideBar ? Math.min(34, BarLayout.elementThickness(root.appearance) - 6) : 34
        height: root.sideBar ? 4 : icon.height

        Rectangle {
            anchors.centerIn: parent
            width: parent.width
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
    }

    // As high as the icon beside it, so the percentage stays centred on it
    // when the icon is bigger than the text.
    Item {
        visible: !root.meterVisible
        width: percentage.width
        height: root.sideBar ? percentage.height : icon.height

        ElementText {
            id: percentage

            anchors.centerIn: parent
            appearance: root.appearance
            value: VolumeText.percentage(root.volume)
            color: root.muted ? theme.textMuted : theme.blue
            font.pixelSize: root.appearance.textSize
            font.bold: true
        }
    }
}
