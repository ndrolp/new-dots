import QtQuick
import "../../config" as Config

Column {
    id: root

    property var appearance
    readonly property var workspaceIds: [
        1, 2, 3, 4, 5, 6, 7, 8, 9, 10,
        11, 12, 13, 14, 15, 16, 17, 18, 19, 20
    ]

    width: parent ? parent.width : 0
    spacing: 12

    Config.Theme {
        id: theme
    }

    Text {
        text: "WORKSPACE LABELS"
        color: theme.textMuted
        font.pixelSize: 11
        font.bold: true
    }

    Column {
        width: parent.width
        spacing: 8

        Rectangle {
            width: parent.width
            height: 44
            radius: root.appearance.radius
            color: glyphToggleHover.hovered ? theme.surfaceHover : theme.backgroundSecondary

            HoverHandler {
                id: glyphToggleHover
            }

            Text {
                anchors.left: parent.left
                anchors.leftMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                text: "USE WORKSPACE GLYPHS"
                color: theme.text
                font.pixelSize: root.appearance.textSize - 1
                font.bold: true
            }

            Rectangle {
                anchors.right: parent.right
                anchors.rightMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                width: 48
                height: 28
                radius: root.appearance.radius
                color: root.appearance.workspaceGlyphsEnabled ? theme.accent : theme.surface

                Rectangle {
                    x: root.appearance.workspaceGlyphsEnabled ? parent.width - width - 3 : 3
                    anchors.verticalCenter: parent.verticalCenter
                    width: 22
                    height: 22
                    radius: 11
                    color: theme.text

                    Behavior on x {
                        NumberAnimation {
                            duration: 160
                            easing.type: Easing.OutCubic
                        }
                    }
                }
            }

            TapHandler {
                onTapped: root.appearance.workspaceGlyphsEnabled
                    = !root.appearance.workspaceGlyphsEnabled
            }
        }

        Text {
            width: parent.width
            text: "Leave a glyph empty to show its workspace number."
            color: theme.textMuted
            font.pixelSize: root.appearance.textSize - 2
            font.bold: true
        }

        Grid {
            width: parent.width
            height: 292
            columns: 4
            columnSpacing: 8
            rowSpacing: 8

            Repeater {
                model: root.workspaceIds

                delegate: Column {
                    required property int modelData

                    width: (parent.width - parent.columnSpacing * 3) / 4
                    spacing: 4

                    Text {
                        text: "WORKSPACE " + modelData
                        color: theme.textMuted
                        font.pixelSize: 10
                        font.bold: true
                    }

                    SettingsInput {
                        width: parent.width
                        appearance: root.appearance
                        text: root.appearance.workspaceGlyphs
                            && root.appearance.workspaceGlyphs.length >= modelData
                            ? root.appearance.workspaceGlyphs[modelData - 1] : ""
                        placeholderText: String(modelData)
                        maximumLength: 4

                        onTextEdited: {
                            const glyphs = root.appearance.workspaceGlyphs.slice();
                            glyphs[modelData - 1] = text;
                            root.appearance.workspaceGlyphs = glyphs;
                        }
                    }
                }
            }
        }
    }
}
