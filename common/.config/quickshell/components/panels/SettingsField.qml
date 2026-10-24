import QtQuick
import "../../config" as Config
import "." as Panels

// A setting whose control carries no name of its own (a choice, a text
// field…): its label on top, then the control, which is the part's child and
// sets its width to the part's. A `small` label, muted and a little smaller,
// suits fields packed into a list row.
Column {
    id: field

    required property var appearance
    property string label: ""
    property bool small: false

    spacing: small ? 4 : 6

    Config.Theme {
        id: theme
    }

    Panels.SettingsLabel {
        width: parent.width
        appearance: field.appearance
        text: field.label
        color: field.small ? theme.textMuted : theme.text
        font.pixelSize: field.small ? field.appearance.textSize - 1 : field.appearance.textSize
    }
}
