import QtQuick
import "../../config" as Config

// The capsule's workspace row: one round pill per workspace of its monitor, in
// the profile's background colour and opacity like the capsule, with the bar
// border around each when that setting is on. The active workspace's pill is
// highlighted and wider; a click on a pill switches to its workspace.
Row {
    id: root

    // The monitor's workspaces, in the order the workspace service lists them.
    required property var workspaceIds
    // Tells which workspace is active and switches to one
    // (services/WorkspaceService.qml).
    required property var workspaceService
    required property color fillColor
    property color activeColor: theme.accent
    // Whether the bar border runs around each pill.
    property bool border: false
    property color borderColor: "transparent"
    // The bar's appearance: its sizes, spacing and motion.
    required property var appearance
    // How deep every pill is: a workspace button and the pill padding on
    // either side of it.
    readonly property real pillDepth: appearance.workspaceButtonSize + appearance.pillVerticalPadding * 2
    // The pills, in order.
    readonly property var pills: {
        const items = [];
        for (let index = 0; index < pillRepeater.count; index++)
            items.push(pillRepeater.itemAt(index));
        return items.filter(item => item !== null);
    }

    spacing: appearance.spacing

    Repeater {
        id: pillRepeater

        model: root.workspaceIds

        delegate: Rectangle {
            id: pill

            required property var modelData
            readonly property int workspaceId: modelData
            readonly property bool active: root.workspaceService.isActive(workspaceId)

            width: root.pillDepth + (active ? root.appearance.activeWorkspaceHorizontalPadding * 2 : 0)
            height: root.pillDepth
            radius: height / 2
            color: active ? root.activeColor : root.fillColor
            border.width: root.border ? 1 : 0
            border.color: root.border ? root.borderColor : "transparent"

            AlongBarBehavior on width { appearance: root.appearance }

            Behavior on color {
                ColorAnimation {
                    duration: root.appearance.motion.short
                }
            }

            ShellText {
                anchors.centerIn: parent
                text: pill.workspaceId
                color: pill.active ? theme.background : theme.text
                font.pixelSize: root.appearance.textSize
                font.bold: true
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.workspaceService.switchTo(pill.workspaceId)
            }
        }
    }

    Config.Theme {
        id: theme
    }
}
