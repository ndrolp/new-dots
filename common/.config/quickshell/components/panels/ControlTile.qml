import QtQuick
import "../../config" as Config
import "." as Panels

// A Tile of the control center: a switch (on or off) or an action, a small
// card with a colored icon above its label. An active tile is tinted with
// its color; the rest stay muted until hovered. A tile whose control isn't
// available is faded and doesn't react.
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

    height: labelShown ? 64 : 44
    interactive: controlEnabled
    opacity: controlEnabled ? 1 : 0.45
    color: tile.active
        ? Qt.rgba(accentColor.r, accentColor.g, accentColor.b, tile.hovered ? 0.22 : 0.15)
        : interactive && hovered ? tileTheme.surfaceHover : tileTheme.backgroundSecondary
    border.width: 1
    border.color: tile.active
        ? Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.35)
        : Qt.rgba(tileTheme.border.r, tileTheme.border.g, tileTheme.border.b,
            interactive && hovered ? 0.9 : 0.5)

    Behavior on border.color {
        ColorAnimation { duration: tile.appearance.motion.short }
    }

    Config.Theme {
        id: tileTheme
    }

    Column {
        anchors.centerIn: parent
        width: parent.width - 12
        spacing: 4

        Panels.Text {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            text: tile.icon
            color: tile.active || tile.hovered ? tile.accentColor : tileTheme.textMuted
            font.pixelSize: tile.appearance.textSize + 9

            Behavior on color {
                ColorAnimation { duration: tile.appearance.motion.short }
            }
        }

        Panels.Text {
            width: parent.width
            visible: tile.labelShown
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
            text: tile.label
            color: tile.active ? tileTheme.text : tileTheme.textMuted
            font.pixelSize: tile.appearance.textSize - 3
        }
    }

    TapHandler {
        enabled: tile.controlEnabled
        onTapped: tile.triggered()
    }
}
