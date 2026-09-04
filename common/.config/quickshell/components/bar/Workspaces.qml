import QtQuick
import "../../config" as Config

Rectangle {
    id: root

    required property var appearance
    required property var monitorScreen
    required property var monitors
    required property var workspaceService

    implicitWidth: workspaceRow.implicitWidth + (appearance.barTransparent ? 16 : 0)
    implicitHeight: workspaceRow.implicitHeight + (appearance.barTransparent
        ? (appearance.pillVerticalPadding + 2) * 2 : 0)
    width: implicitWidth
    height: implicitHeight
    radius: appearance.radius
    color: appearance.barTransparent && !appearance.pillsTransparent
        && !appearance.transparentBarSlanted && !appearance.statusIsland ? theme.surface : "transparent"

    Behavior on color {
        ColorAnimation {
            duration: 140
        }
    }

    Behavior on width {
        NumberAnimation {
            duration: 180
            easing.type: Easing.OutCubic
        }
    }

    Row {
        id: workspaceRow

        anchors.centerIn: parent
        spacing: appearance.spacing

        move: Transition {
            NumberAnimation {
                properties: "x"
                duration: 180
                easing.type: Easing.OutCubic
            }
        }

        Repeater {
            model: root.workspaceService.workspacesForScreen(
                root.monitorScreen,
                root.monitors.workspacesFor(root.workspaceService.monitorDescriptionForScreen(root.monitorScreen))
            ).filter(workspaceId => !root.appearance.hideEmptyWorkspaces
                || root.workspaceService.isActive(workspaceId)
                || root.workspaceService.isOccupied(workspaceId)
                || root.workspaceService.isUrgent(workspaceId))

            delegate: Rectangle {
                id: workspaceButton

                required property var modelData
                readonly property int workspaceId: modelData
                readonly property bool active: root.workspaceService.isActive(workspaceId)
                readonly property bool occupied: root.workspaceService.isOccupied(workspaceId)
                readonly property bool urgent: !active
                    && root.workspaceService.isUrgent(workspaceId)
                readonly property string workspaceGlyph: root.appearance.workspaceGlyphsEnabled
                    && root.appearance.workspaceGlyphs
                    && root.appearance.workspaceGlyphs.length >= workspaceId
                    ? String(root.appearance.workspaceGlyphs[workspaceId - 1]).trim() : ""

                width: active
                    ? appearance.workspaceButtonSize + (appearance.activeWorkspaceHorizontalPadding * 2)
                    : appearance.workspaceButtonSize
                height: appearance.barTransparent
                    ? appearance.workspaceButtonSize - 2
                    : appearance.barHeight - (appearance.workspacePadding * 2)
                radius: appearance.radius
                color: active ? theme.accent : urgent
                    ? Qt.rgba(theme.red.r, theme.red.g, theme.red.b, 0.22)
                    : occupied && !appearance.pillsTransparent && !appearance.transparentBarSlanted
                        && !appearance.statusIsland
                        ? theme.surface : "transparent"
                border.color: urgent ? theme.red : "transparent"
                border.width: urgent ? 1 : 0

                Behavior on width {
                    NumberAnimation {
                        duration: 180
                        easing.type: Easing.OutCubic
                    }
                }

                Behavior on x {
                    NumberAnimation {
                        duration: 180
                        easing.type: Easing.OutCubic
                    }
                }

                Behavior on color {
                    ColorAnimation {
                        duration: 140
                    }
                }

                Text {
                    anchors.centerIn: parent
                    text: workspaceButton.workspaceGlyph !== ""
                        ? workspaceButton.workspaceGlyph : workspaceButton.workspaceId
                    color: workspaceButton.active ? theme.background : workspaceButton.urgent
                        ? theme.red : workspaceButton.occupied ? theme.text : theme.textDisabled
                    font.family: theme.fontFamily
                    font.pixelSize: appearance.textSize
                    font.bold: true

                    Behavior on color {
                        ColorAnimation {
                            duration: 80
                        }
                    }

                }

                HoverHandler {
                    id: hover
                }

                Rectangle {
                    anchors.fill: parent
                    radius: appearance.radius
                    color: theme.surfaceHover
                    opacity: hover.hovered && !workspaceButton.active ? 1 : 0

                    Behavior on opacity {
                        NumberAnimation {
                            duration: 140
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: workspaceButton.workspaceGlyph !== ""
                            ? workspaceButton.workspaceGlyph : workspaceButton.workspaceId
                        color: theme.text
                        font.family: theme.fontFamily
                        font.pixelSize: appearance.textSize
                        font.bold: true
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.workspaceService.switchTo(workspaceButton.workspaceId)
                }
            }
        }
    }

    Config.Theme {
        id: theme
    }
}
