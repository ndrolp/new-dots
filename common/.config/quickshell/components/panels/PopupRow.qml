import QtQuick
import "../../config" as Config

// A row that stays transparent until hovered. A selected row shows it with
// the accent color in its contents, not with a fill.
Rectangle {
    required property var appearance
    readonly property alias hovered: rowHover.hovered
    property bool interactive: true

    radius: appearance.radius
    color: interactive && hovered ? theme.surfaceHover : "transparent"

    Behavior on color {
        ColorAnimation { duration: appearance.motion.short }
    }

    Config.Theme {
        id: theme
    }

    HoverHandler {
        id: rowHover

        enabled: parent.interactive
    }
}
