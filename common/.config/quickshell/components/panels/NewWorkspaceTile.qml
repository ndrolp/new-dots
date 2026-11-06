import QtQuick
import "WorkspaceOverview.js" as WorkspaceOverview

// The empty tile after a monitor's last workspace. A window dropped here goes to
// a new workspace, following the same rules as any other drop. It isn't a
// workspace, so a click on it passes through as one outside any workspace.
Rectangle {
    id: root

    required property var appearance
    required property var colors
    // The number the new workspace takes.
    property int workspace: -1
    readonly property bool lit: windowDrop.containsDrag

    signal windowDropped(QtObject window)

    radius: appearance.radius
    color: lit ? Qt.rgba(colors.accent.r, colors.accent.g, colors.accent.b, 0.4) : "transparent"
    border.color: lit ? colors.accent : colors.border
    border.width: lit ? 2 : 1

    Behavior on color {
        ColorAnimation { duration: root.appearance.motion.short }
    }

    WindowDropTarget {
        id: windowDrop

        anchors.fill: parent
        accepts: window => WorkspaceOverview.movesTo(window.lastIpcObject, root.workspace)
        onWindowDropped: window => root.windowDropped(window)
    }

    Text {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.margins: 6
        text: "+  " + root.workspace
        color: root.lit ? root.colors.accent : root.colors.textDisabled
        font.pixelSize: root.appearance.textSize
        font.bold: true
    }

    Text {
        anchors.centerIn: parent
        text: "New workspace"
        color: root.colors.textDisabled
        font.pixelSize: root.appearance.textSize - 3
    }
}
