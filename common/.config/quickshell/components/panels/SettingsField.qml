import QtQuick
import "." as Panels

// A setting whose control carries no name of its own (a choice, a text
// field…): its label on top, then the control, which is the part's child and
// sets its width to the part's.
Column {
    id: field

    required property var appearance
    property string label: ""

    spacing: 6

    Panels.SettingsLabel {
        width: parent.width
        appearance: field.appearance
        text: field.label
    }
}
