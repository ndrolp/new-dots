import QtQuick
import "BarPlacement.js" as BarPlacement
import "CapsulePills.js" as CapsulePills
import "../../services/WorkspaceState.js" as WorkspaceState
import ".." as Components
import "../../config" as Config

// The capsule's workspace pills, inside the capsule past its row of bar
// elements: one small pill, with no label, per workspace of its monitor with
// windows, and the active one even when empty; an empty one has no pill
// (CapsulePills.hasRestingPill). The active workspace's pill is twice as long and in
// the accent, one asking for attention is red and one with windows dim. A
// click on a pill switches to its workspace; scrolling over the pills goes to
// the next or previous workspace, an empty one too, at most one per touchpad
// gesture, stopping at either end.
Row {
    id: root

    // The monitor's workspaces, in the order the workspace service lists them;
    // scrolling goes through all of them, pill or not.
    required property var workspaceIds
    // Tells which workspace is active and switches to one
    // (services/WorkspaceService.qml).
    required property var workspaceService
    // The screen of its monitor, whose shown workspace scrolling starts from.
    required property var monitorScreen
    property color activeColor: theme.accent
    property color urgentColor: theme.red
    property color occupiedColor: Qt.rgba(theme.text.r, theme.text.g, theme.text.b, 0.4)
    // The bar's appearance: its spacing and motion.
    required property var appearance
    readonly property real pillDepth: BarPlacement.workspacePillDepth
    // The pills shown, in order.
    readonly property var pills: {
        const items = [];
        for (let index = 0; index < pillRepeater.count; index++)
            items.push(pillRepeater.itemAt(index));
        return items.filter(item => item !== null && item.visible);
    }

    spacing: appearance.spacing

    // The pills take a scroll a little past their edges, as they take clicks.
    Components.WheelStepHandler {
        margin: root.spacing / 2
        onStepped: step => WorkspaceState.scroll(root.workspaceService, root.monitorScreen,
            root.workspaceIds, step)
    }

    Repeater {
        id: pillRepeater

        model: root.workspaceIds

        delegate: Rectangle {
            id: pill

            required property var modelData
            readonly property int workspaceId: modelData
            readonly property bool active: root.workspaceService.isActive(workspaceId)
            readonly property bool urgent: !active && root.workspaceService.isUrgent(workspaceId)

            // A workspace without a pill keeps its place in the Repeater, so
            // the others keep theirs and animate, but the Row skips it.
            visible: CapsulePills.hasRestingPill(workspaceId, root.workspaceService)

            width: root.pillDepth * (active ? 4 : 2)
            height: root.pillDepth
            radius: height / 2
            color: active ? root.activeColor : urgent ? root.urgentColor : root.occupiedColor

            AlongBarBehavior on width { appearance: root.appearance }

            Behavior on color {
                ColorAnimation {
                    duration: root.appearance.motion.short
                }
            }

            // The pills are small: each takes clicks a little past its edges.
            MouseArea {
                anchors.fill: parent
                anchors.margins: -root.spacing / 2
                cursorShape: Qt.PointingHandCursor
                onClicked: root.workspaceService.switchTo(pill.workspaceId)
            }
        }
    }

    Config.Theme {
        id: theme
    }
}
