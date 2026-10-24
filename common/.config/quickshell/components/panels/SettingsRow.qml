import QtQuick
import "../../config" as Config

// A full-width row of a settings list: transparent until hovered, when it
// takes a faint fill. What it shows is its children.
Rectangle {
    id: row

    required property var appearance
    readonly property alias hovered: rowHover.hovered

    radius: appearance.radius
    color: rowHover.hovered ? theme.surfaceHover : "transparent"

    Behavior on color {
        ColorAnimation { duration: 140 }
    }

    Config.Theme {
        id: theme
    }

    HoverHandler {
        id: rowHover
    }
}
