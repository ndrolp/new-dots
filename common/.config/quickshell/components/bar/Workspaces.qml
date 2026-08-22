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
        && !appearance.transparentBarSlanted ? theme.surface : "transparent"

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
            )

            delegate: Rectangle {
                id: workspaceButton

                required property var modelData
                readonly property int workspaceId: modelData
                readonly property bool active: root.workspaceService.isActive(workspaceId)
                readonly property bool occupied: root.workspaceService.isOccupied(workspaceId)

                width: active
                    ? appearance.workspaceButtonSize + (appearance.activeWorkspaceHorizontalPadding * 2)
                    : appearance.workspaceButtonSize
                height: appearance.barTransparent
                    ? appearance.workspaceButtonSize - 2
                    : appearance.barHeight - (appearance.workspacePadding * 2)
                radius: appearance.radius
                color: active ? theme.accent
                    : occupied && !appearance.pillsTransparent && !appearance.transparentBarSlanted
                        ? theme.surface : "transparent"

                Behavior on width {
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
                    text: workspaceButton.workspaceId
                    color: workspaceButton.active ? theme.background : workspaceButton.occupied ? theme.text : theme.textDisabled
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
                        text: workspaceButton.workspaceId
                        color: theme.text
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
