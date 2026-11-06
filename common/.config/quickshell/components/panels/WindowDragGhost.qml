import Quickshell.Widgets
import QtQuick
import "../../config" as Config
import "../IconSource.js" as IconSource
import "WorkspaceOverview.js" as WorkspaceOverview

// What follows the pointer while a window is dragged: its thumbnail, over its
// icon for a window with no captured frame.
Rectangle {
    id: root

    required property var appearance
    required property Item frames
    required property QtObject window

    readonly property var windowInfo: window ? window.lastIpcObject : ({})
    readonly property var size: WorkspaceOverview.ghostSize(windowInfo, 160)

    width: size.width
    height: size.height
    clip: true
    radius: appearance.radius / 2
    color: theme.surface
    border.color: theme.accent
    border.width: 1

    Config.Theme {
        id: theme
    }

    IconImage {
        anchors.centerIn: parent
        width: Math.min(40, parent.width - 4, parent.height - 4)
        height: width
        source: IconSource.forName(WorkspaceOverview.appClass(root.windowInfo))
    }

    WindowThumbnail {
        anchors.fill: parent
        anchors.margins: parent.border.width
        frame: root.window ? root.frames.frameOf(root.window) : null
    }
}
