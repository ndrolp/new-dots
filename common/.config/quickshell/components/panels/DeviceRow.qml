import QtQuick
import "../../config" as Config
import "." as Panels

// One row of a device list (the Printers panel's printers and scanners,
// the Android devices panel's Android devices): a glyph, the device's name
// and a line under it (how it's connected, its state). What goes on the
// right (buttons, the Default badge) is the section's, put in the row and
// kept clear of with `trailingWidth`.
Panels.PopupRow {
    id: row

    property string glyph: "󰐪"
    property color glyphColor: theme.textMuted
    property string title: ""
    property string subtitle: ""
    property color subtitleColor: theme.textMuted
    // How much of the right is the section's.
    property real trailingWidth: 0

    height: 44

    Config.Theme {
        id: theme
    }

    Panels.ShellText {
        id: glyphText

        anchors.left: parent.left
        anchors.leftMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        text: row.glyph
        color: row.glyphColor
        font.pixelSize: row.appearance.textSize + 6
    }

    Column {
        anchors.left: glyphText.right
        anchors.leftMargin: 10
        anchors.right: parent.right
        anchors.rightMargin: row.trailingWidth + 8
        anchors.verticalCenter: parent.verticalCenter

        Panels.ShellText {
            width: parent.width
            text: row.title
            elide: Text.ElideRight
            color: theme.text
            font.pixelSize: row.appearance.textSize - 1
        }

        Panels.ShellText {
            width: parent.width
            text: row.subtitle
            elide: Text.ElideRight
            color: row.subtitleColor
            font.pixelSize: row.appearance.textSize - 3
        }
    }
}
