import Quickshell.Widgets
import QtQuick
import "../IconSource.js" as IconSource
import "WorkspaceOverview.js" as WorkspaceOverview

// What follows the pointer while a window is dragged: its thumbnail, over its
// icon for a window with no captured frame.
Rectangle {
    id: root

    required property var appearance
    required property var colors
    required property Item frames
    required property QtObject window

    readonly property var details: window ? window.lastIpcObject : ({})
    readonly property var size: WorkspaceOverview.ghostSize(details, 160)

    width: size.width
    height: size.height
    clip: true
    radius: appearance.radius / 2
    color: colors.surface
    border.color: colors.accent
    border.width: 1

    IconImage {
        anchors.centerIn: parent
        width: Math.min(40, parent.width - 4, parent.height - 4)
        height: width
        source: IconSource.forName(WorkspaceOverview.appClass(root.details))
    }

    WindowThumbnail {
        anchors.fill: parent
        anchors.margins: parent.border.width
        frame: root.window ? root.frames.frameOf(root.window) : null
    }
}
