import Quickshell.Widgets
import QtQuick
import "../../config" as Config
import "../IconSource.js" as IconSource
import "WorkspaceOverview.js" as WorkspaceOverview

// A window in its workspace's miniature, in its real place: its thumbnail over
// its icon and title. A press on it goes to the WindowDrag.
Rectangle {
    id: root

    required property var appearance
    required property Item frames
    required property Item drag
    // The real monitor, and the miniature showing it.
    required property var monitor
    required property Item miniature
    required property var modelData

    readonly property var toplevel: modelData
    readonly property var windowInfo: toplevel.lastIpcObject
    readonly property var box: WorkspaceOverview.windowBox(windowInfo, monitor, miniature)
    readonly property string appClass: WorkspaceOverview.appClass(windowInfo)

    x: box.x
    y: box.y
    z: WorkspaceOverview.stacking(windowInfo)
    width: box.width
    height: box.height
    clip: true
    radius: appearance.radius / 2
    color: windowHover.hovered ? theme.surfaceHover : theme.surface
    border.color: theme.border
    border.width: 1

    Config.Theme {
        id: theme
    }

    HoverHandler {
        id: windowHover
    }

    IconImage {
        id: windowIcon

        anchors.centerIn: parent
        anchors.verticalCenterOffset: windowTitle.visible ? -10 : 0
        width: Math.max(0, Math.min(24, parent.width - 4, parent.height - 4))
        height: width
        source: IconSource.forName(root.appClass)
    }

    Text {
        id: windowTitle

        anchors.top: windowIcon.bottom
        anchors.topMargin: 2
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 4
        visible: parent.height > 48
        text: root.toplevel.title || root.appClass
        color: theme.text
        elide: Text.ElideRight
        horizontalAlignment: Text.AlignHCenter
        font.pixelSize: root.appearance.textSize - 4
    }

    WindowThumbnail {
        anchors.fill: parent
        anchors.margins: parent.border.width
        frame: root.frames.frameOf(root.toplevel)
        // The hover colour shows through.
        opacity: windowHover.hovered ? 0.85 : 1
    }

    // A MouseArea so a click here doesn't reach the miniature below.
    MouseArea {
        anchors.fill: parent
        onPressed: root.drag.press(root.toplevel, WorkspaceOverview.canDrag(root.windowInfo))
    }
}
