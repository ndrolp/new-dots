import QtQuick
import "../../config" as Config
import "." as Panels

// A headed group of settings: a hairline border, a half-transparent fill one
// step lighter than the panel, its heading inside at the top and 16px of
// padding. Every section puts each of its groups in one, 12px apart. The card has no hover
// of its own; only the controls in it react. What it holds is its children,
// stacked like a section's, `width: parent.width` filling the padded width.
Rectangle {
    id: card

    required property var appearance
    // The group's heading; a card without one starts with its content.
    property string title: ""
    property alias spacing: content.spacing
    default property alias content: content.data

    width: parent ? parent.width : 0
    implicitHeight: column.implicitHeight + 32
    height: implicitHeight
    radius: appearance.radius
    color: Qt.rgba(theme.surfaceHover.r, theme.surfaceHover.g, theme.surfaceHover.b, 0.5)
    border.color: theme.border
    border.width: 1

    Config.Theme {
        id: theme
    }

    Column {
        id: column

        x: 16
        y: 16
        width: card.width - 32
        spacing: 10

        Panels.SettingsHeading {
            width: parent.width
            visible: card.title !== ""
            appearance: card.appearance
            text: card.title
        }

        Column {
            id: content

            width: parent.width
            spacing: 14
        }
    }
}
