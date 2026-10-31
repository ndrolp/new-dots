import QtQuick
import "." as Panels
import "../../config" as Config
import "../../config/ControlCenterTiles.js" as ControlCenterTiles

// The Control center section: the control center's tiles, one global ordered
// list (global, not part of any bar profile). Each tile is shown or hidden
// with its switch and moved with its arrows; the first 6 visible tiles form
// the collapsed control center's row, so a divider follows the 6th.
Column {
    id: root

    required property var appearance
    readonly property var tiles: appearance.controlCenterTiles
    readonly property string dividerAfter: ControlCenterTiles.dividerAfter(tiles)

    width: parent ? parent.width : 0
    spacing: 6

    Config.Theme {
        id: theme
    }

    Panels.SettingsHeading {
        appearance: root.appearance
        text: "Tiles"
        topPadding: 4
    }

    Panels.SettingsHint {
        width: root.width
        appearance: root.appearance
        text: "Every tile of the control center, in order. The first 6 shown tiles form the collapsed row; expanded, every shown tile appears."
    }

    Column {
        width: root.width
        spacing: 2

        Repeater {
            model: root.tiles

            delegate: Column {
                id: tileDelegate

                required property var modelData
                required property int index
                readonly property bool tileShown: modelData.enabled !== false

                width: root.width
                spacing: 2

                Panels.SettingsRow {
                    readonly property string tileLabel: ControlCenterTiles.tileLabels[tileDelegate.modelData.id]
                        || tileDelegate.modelData.id

                    width: parent.width
                    height: 40
                    appearance: root.appearance

                    Panels.SettingsLabel {
                        anchors.left: parent.left
                        anchors.leftMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        appearance: root.appearance
                        text: parent.tileLabel
                        color: tileDelegate.tileShown ? theme.text : theme.textMuted
                    }

                    Row {
                        anchors.right: parent.right
                        anchors.rightMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 8

                        Panels.SettingsMoveButtons {
                            anchors.verticalCenter: parent.verticalCenter
                            appearance: root.appearance
                            canMoveUp: tileDelegate.index > 0
                            canMoveDown: tileDelegate.index < root.tiles.length - 1
                            onMovedUp: root.appearance.moveControlCenterTile(tileDelegate.modelData.id, -1)
                            onMovedDown: root.appearance.moveControlCenterTile(tileDelegate.modelData.id, 1)
                        }

                        Panels.SettingsSwitch {
                            anchors.verticalCenter: parent.verticalCenter
                            appearance: root.appearance
                            checked: tileDelegate.tileShown

                            TapHandler {
                                onTapped: root.appearance.setControlCenterTileEnabled(
                                    tileDelegate.modelData.id, !tileDelegate.tileShown)
                            }
                        }
                    }
                }

                // Everything above it is the collapsed row.
                Item {
                    visible: root.dividerAfter === tileDelegate.modelData.id
                    width: parent.width
                    height: 28

                    Rectangle {
                        anchors.left: parent.left
                        anchors.right: dividerLabel.left
                        anchors.leftMargin: 12
                        anchors.rightMargin: 10
                        anchors.verticalCenter: parent.verticalCenter
                        height: 1
                        color: theme.border
                    }

                    Panels.SettingsHint {
                        id: dividerLabel

                        anchors.centerIn: parent
                        appearance: root.appearance
                        text: "Collapsed row above"
                    }

                    Rectangle {
                        anchors.left: dividerLabel.right
                        anchors.right: parent.right
                        anchors.leftMargin: 10
                        anchors.rightMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        height: 1
                        color: theme.border
                    }
                }
            }
        }
    }
}
