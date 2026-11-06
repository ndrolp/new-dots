import Quickshell.Widgets
import QtQuick
import "../IconSource.js" as IconSource
import "WorkspaceOverview.js" as WorkspaceOverview

// What follows the pointer while a window is dragged: its icon for now. A
// thumbnail goes here, in place of the IconImage.
Rectangle {
    id: root

    required property var appearance
    required property var theme
    required property QtObject window

    width: 72
    height: 72
    radius: appearance.radius
    color: theme.surface
    border.color: theme.accent
    border.width: 1

    IconImage {
        anchors.centerIn: parent
        width: 40
        height: width
        source: root.window
            ? IconSource.forName(WorkspaceOverview.appClass(root.window.lastIpcObject)) : ""
    }
}
