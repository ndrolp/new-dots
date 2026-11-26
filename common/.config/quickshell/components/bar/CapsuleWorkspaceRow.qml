import QtQuick
import "BarPlacement.js" as BarPlacement
import "CapsulePills.js" as CapsulePills
import "CapsuleMotion.js" as CapsuleMotion
import "../../services/WorkspaceState.js" as WorkspaceState
import ".." as Components
import "../../config" as Config

// The capsule's workspace pills, inside the capsule past its row of bar
// elements. At rest: one small pill, with no label, per workspace of its
// monitor, an empty one dimmest. The pill of the workspace its monitor shows
// (whichever monitor has focus) is twice as long and in the accent, one asking for attention is
// red and one with windows dim (CapsulePills.role). Expanded, the pills grow
// on the capsule's spring into small chips with the workspace's number, or
// its glyph when the workspaces bar element uses glyphs, in the same
// colours, an empty one dim and clickable; collapsed, they are
// pills again (CapsulePills). A click on a pill switches to its workspace;
// scrolling over the pills goes to the next or previous workspace, an empty
// one too, at most one per touchpad gesture, stopping at either end.
Row {
    id: root

    // The monitor's workspaces, in the order the workspace service lists them,
    // each with its pill; scrolling goes through all of them.
    required property var workspaceIds
    // Tells which workspace its monitor shows and switches to one
    // (services/WorkspaceService.qml).
    required property var workspaceService
    // The screen of its monitor, whose shown workspace has the long pill and
    // scrolling starts from.
    required property var monitorScreen
    // Whether the capsule is expanded: the pills are chips.
    property bool expanded: false
    // The workspaces bar element's options, for its glyphs.
    property var workspaceOptions: ({ glyphsEnabled: false, glyphs: [] })
    property color activeColor: theme.accent
    property color urgentColor: theme.red
    property color occupiedColor: Qt.rgba(theme.text.r, theme.text.g, theme.text.b, 0.4)
    property color emptyColor: Qt.rgba(theme.text.r, theme.text.g, theme.text.b, 0.15)
    // The bar's appearance: its spacing, text size and motion.
    required property var appearance
    // How deep the pills are headed to be, the chips' depth expanded, and how
    // long the lot: where they are going, not where they are mid-spring, so
    // the capsule springs to fit them once.
    readonly property real depth: expanded ? BarPlacement.workspaceChipDepth(appearance)
        : BarPlacement.workspacePillDepth
    readonly property real length: pills.reduce((total, pill) => total + pill.size.width, 0)
        + Math.max(0, pills.length - 1) * spacing
    // The pills, one per workspace, in order. Read whether or not the row is
    // shown: the bar shows it only once the capsule has a place, which takes
    // its length.
    readonly property var pills: {
        const items = [];
        for (let index = 0; index < pillRepeater.count; index++)
            items.push(pillRepeater.itemAt(index));
        return items.filter(item => item !== null);
    }
    // The capsule's spring for the way it is going now (CapsuleMotion.springFor).
    readonly property var spring: CapsuleMotion.springFor(appearance.motion, expanded)

    height: depth
    spacing: appearance.spacing

    // The pills take a scroll a little past their edges, as they take clicks.
    Components.WheelStepHandler {
        margin: root.spacing / 2
        onStepped: step => WorkspaceState.scroll(root.workspaceService, root.monitorScreen,
            root.workspaceIds, step)
    }

    // A pill's size moving on the capsule's spring.
    component Spring: Behavior {
        NumberAnimation {
            duration: root.spring.duration
            easing.type: root.spring.easing
            easing.overshoot: root.spring.overshoot
        }
    }

    Repeater {
        id: pillRepeater

        model: root.workspaceIds

        delegate: Rectangle {
            id: pill

            required property var modelData
            readonly property int workspaceId: modelData
            readonly property string role: CapsulePills.role(workspaceId, root.workspaceService,
                root.monitorScreen)
            // Where its size is headed (CapsulePills.size).
            readonly property var size: CapsulePills.size(role, root.expanded, {
                pillDepth: BarPlacement.workspacePillDepth,
                chipDepth: BarPlacement.workspaceChipDepth(root.appearance),
                labelLength: chipLabel.implicitWidth
            })
            property alias label: chipLabel

            width: size.width
            height: size.height
            y: (root.depth - height) / 2
            radius: height / 2
            color: role === "shown" ? root.activeColor : role === "urgent" ? root.urgentColor
                : role === "occupied" ? root.occupiedColor : root.emptyColor

            Spring on width {}
            Spring on height {}

            Behavior on color {
                ColorAnimation {
                    duration: root.appearance.motion.short
                }
            }

            // Its number or glyph, only on a chip.
            ShellText {
                id: chipLabel

                anchors.centerIn: parent
                text: CapsulePills.label(pill.workspaceId, root.workspaceOptions)
                color: pill.role === "shown" || pill.role === "urgent" ? theme.background
                    : pill.role === "occupied" ? theme.text : theme.textDisabled
                font.pixelSize: Math.round(BarPlacement.workspaceChipDepth(root.appearance) * 0.65)
                font.bold: true
                opacity: root.expanded ? 1 : 0
                visible: opacity > 0

                Behavior on opacity {
                    NumberAnimation {
                        duration: root.spring.duration
                        easing.type: root.appearance.motion.easing
                    }
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
