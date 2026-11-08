import Quickshell
import QtQuick
import "../../config" as Config

// A workspace in the workspace overview: a small copy of its monitor with the
// windows in their place.
WorkspaceDropSurface {
    id: root

    required property var workspaceService
    required property var monitor
    required property Item frames
    required property Item drag
    required property bool selected
    readonly property bool active: workspaceService.isActive(workspace)

    signal clicked()

    clip: true
    restColor: selected ? Qt.rgba(theme.accent.r, theme.accent.g, theme.accent.b, 0.2)
        : active ? theme.surfaceHover : theme.backgroundSecondary
    restBorderColor: selected ? theme.accent : active ? theme.border : "transparent"
    restBorderWidth: selected || active ? 1 : 0

    Config.Theme {
        id: theme
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.clicked()
    }

    Item {
        anchors.fill: parent

        Repeater {
            id: windowItems

            model: ScriptModel {
                values: root.workspaceService.windowsOn(root.workspace)
            }

            delegate: MiniatureWindow {
                appearance: root.appearance
                frames: root.frames
                drag: root.drag
                monitor: root.monitor
                miniature: root
            }
        }
    }

    ShellText {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.margins: 6
        text: "󰍹  " + root.workspace
        color: root.selected ? theme.accent : theme.text
        style: Text.Outline
        styleColor: theme.surface
        font.pixelSize: root.appearance.textSize
        font.bold: true
    }

    ShellText {
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 6
        text: "ACTIVE"
        visible: root.active
        color: theme.accent
        style: Text.Outline
        styleColor: theme.surface
        font.pixelSize: root.appearance.textSize - 4
        font.bold: true
    }

    ShellText {
        anchors.centerIn: parent
        visible: windowItems.count === 0
        text: "Empty workspace"
        color: theme.textDisabled
        font.pixelSize: root.appearance.textSize - 3
    }
}
