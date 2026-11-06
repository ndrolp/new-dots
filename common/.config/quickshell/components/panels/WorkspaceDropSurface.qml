import QtQuick
import "../../config" as Config

// Where a dragged window can land on a workspace, a miniature or the new workspace
// slot. It lights up in the accent colour while a window it takes is over it, and
// shows its rest colours otherwise.
Rectangle {
    id: root

    required property var appearance
    required property int workspace
    property color restColor: "transparent"
    property color restBorderColor: "transparent"
    property int restBorderWidth: 0
    readonly property bool highlighted: windowDrop.containsDrag

    signal windowDropped(QtObject window)

    radius: appearance.radius
    color: highlighted ? Qt.rgba(theme.accent.r, theme.accent.g, theme.accent.b, 0.4) : restColor
    border.color: highlighted ? theme.accent : restBorderColor
    border.width: highlighted ? 2 : restBorderWidth

    Behavior on color {
        ColorAnimation { duration: root.appearance.motion.short }
    }

    Config.Theme {
        id: theme
    }

    WindowDropTarget {
        id: windowDrop

        anchors.fill: parent
        workspace: root.workspace
        onWindowDropped: window => root.windowDropped(window)
    }
}
