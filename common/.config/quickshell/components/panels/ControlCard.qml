import QtQuick
import "../../config" as Config

// A section card of the control center (the sliders, the system stats): a
// faint fill with a subtle border around its content, padded by `padding`.
Rectangle {
    id: card

    required property var appearance
    property int padding: 12
    default property alias content: inner.data

    implicitHeight: inner.implicitHeight + padding * 2
    height: implicitHeight
    radius: appearance.radius
    color: theme.backgroundSecondary
    border.width: 1
    border.color: Qt.rgba(theme.border.r, theme.border.g, theme.border.b, 0.5)

    Config.Theme {
        id: theme
    }

    Column {
        id: inner

        x: card.padding
        y: card.padding
        width: card.width - card.padding * 2
        spacing: 12
    }
}
