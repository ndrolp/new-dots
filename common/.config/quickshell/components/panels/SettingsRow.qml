import QtQuick
import "../../config" as Config

// A full-width row of a settings list: transparent until hovered, when it
// takes a faint fill. A row that does something when clicked shows a
// pointing hand. What it shows is its children.
Rectangle {
    id: row

    required property var appearance
    property bool clickable: false
    // Follows the pointer; settable so its look can be checked without one.
    property bool hovered: rowHover.hovered

    radius: appearance.radius
    color: hovered ? theme.surfaceHover : "transparent"

    Behavior on color {
        ColorAnimation { duration: row.appearance.motion.short }
    }

    Config.Theme {
        id: theme
    }

    HoverHandler {
        id: rowHover

        cursorShape: row.clickable ? Qt.PointingHandCursor : Qt.ArrowCursor
    }
}
