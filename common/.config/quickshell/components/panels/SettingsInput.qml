import QtQuick
import QtQuick.Controls
import "../../config" as Config
import "." as Panels

// A text or number field: transparent, with a hairline border that turns
// accent while focused. Hovered, it takes the faint fill and the accent border. Finishing an edit (Return, or leaving the field) asks
// to save the text, once per change: Return and then leaving the field are
// one edit, and an edit that changed nothing asks nothing.
TextField {
    id: control

    required property var appearance
    // The text when the edit began, or when it was last asked to be saved.
    property string savedText: ""
    // Follows the pointer; settable so its look can be checked without one.
    property alias hovering: fieldFill.hovering
    signal edited(string text)

    height: 32
    leftPadding: 10
    rightPadding: 10
    color: theme.text
    placeholderTextColor: theme.textDisabled
    font.family: theme.fontFamily
    font.pixelSize: appearance.textSize
    selectByMouse: true

    onActiveFocusChanged: if (activeFocus) savedText = text
    onEditingFinished: {
        if (text === savedText)
            return;
        savedText = text;
        edited(text);
    }

    TapHandler {
        onTapped: control.forceActiveFocus()
    }

    Config.Theme {
        id: theme
    }

    background: Panels.SettingsHoverFill {
        id: fieldFill

        appearance: control.appearance
        // Deliberately an I-beam, not the pointing hand of the other
        // controls: it is a place to type.
        cursorShape: Qt.IBeamCursor
        radius: control.appearance.radius
        color: hovering ? theme.cardHover : "transparent"
        border.color: control.activeFocus || hovering ? theme.accent : theme.border
        border.width: 1

        Behavior on border.color {
            ColorAnimation { duration: control.appearance.motion.short }
        }
    }
}
