import QtQuick
import "../../config" as Config

// The surface a popup draws on: one flat card with a hairline border and no
// shadow, its contents inset by the padding. It opens with a fade and a short
// slide down. Any window can host it; hide the window while reveal is 0.
Rectangle {
    id: surface

    property bool open: false
    // How far the contents are inset from the border.
    property real padding: 12
    // 0 while closed, 1 once open; animates in between.
    property real reveal: open ? 1 : 0
    readonly property int revealDuration: 120
    // How far above its resting place the surface starts sliding down from.
    readonly property real revealOffset: 8
    default property alias contents: content.data

    implicitHeight: content.height + padding * 2
    color: theme.surface
    border.color: theme.border
    border.width: 1
    radius: theme.radius
    opacity: reveal
    transform: Translate { y: -surface.revealOffset * (1 - surface.reveal) }

    Behavior on reveal {
        NumberAnimation {
            duration: surface.revealDuration
            easing.type: Easing.OutCubic
        }
    }

    Config.Theme {
        id: theme
    }

    Item {
        id: content

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: surface.padding
        height: childrenRect.height
    }
}
