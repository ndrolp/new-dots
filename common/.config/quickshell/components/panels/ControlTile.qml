import QtQuick
import "../../config" as Config
import "." as Panels

// A Tile of the control center: a toggle or action, a row with a colored icon
// and a label. An active tile shows it with its color; the rest stay muted
// until hovered. A tile whose control isn't available is faded and doesn't
// react.
PopupRow {
    id: tile

    required property string label
    required property string icon
    required property color accentColor
    property bool active: false
    property bool controlEnabled: true
    // Off, the tile is its icon alone (the collapsed control center's row).
    property bool labelShown: true

    signal triggered()

    height: 38
    interactive: controlEnabled
    opacity: controlEnabled ? 1 : 0.45

    Config.Theme {
        id: tileTheme
    }

    Row {
        anchors.centerIn: parent
        height: parent.height
        spacing: 6

        Panels.Text {
            anchors.verticalCenter: parent.verticalCenter
            text: tile.icon
            color: tile.active || tile.hovered ? tile.accentColor : tileTheme.textMuted
            font.pixelSize: tile.appearance.textSize + 3

            Behavior on color {
                ColorAnimation { duration: tile.appearance.motion.short }
            }
        }

        Panels.Text {
            anchors.verticalCenter: parent.verticalCenter
            visible: tile.labelShown
            text: tile.label
            color: tile.active ? tileTheme.text : tileTheme.textMuted
            font.pixelSize: tile.appearance.textSize - 2
        }
    }

    TapHandler {
        enabled: tile.controlEnabled
        onTapped: tile.triggered()
    }
}
