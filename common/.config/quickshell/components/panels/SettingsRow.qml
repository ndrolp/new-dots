import QtQuick
import "../../config" as Config
import "." as Panels

// A full-width row of a settings list: transparent until hovered, when it
// takes a faint fill. A row that does something when clicked shows a
// pointing hand. What it shows is its children.
Panels.SettingsHoverFill {
    id: row

    property bool clickable: false

    radius: appearance.radius
    color: hovering ? theme.cardHover : "transparent"
    cursorShape: clickable ? Qt.PointingHandCursor : Qt.ArrowCursor

    Config.Theme {
        id: theme
    }
}
