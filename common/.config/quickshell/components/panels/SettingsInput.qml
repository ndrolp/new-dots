import QtQuick
import QtQuick.Controls
import "../../config" as Config

// A text or number field: transparent, with a hairline border that turns
// accent while focused. Hovered, it takes the faint fill and the accent border. Finishing an edit (Return, or leaving the field) asks
// to save the text, once per change: Return and then leaving the field are
// one edit, and an edit that changed nothing asks nothing.
TextField {
    id: control

    required property var appearance
    // The text when the edit began, or when it was last asked to be saved.
    property string savedText: ""
    // Follows the pointer; settable so its look can be checked without one
    // (a control's own `hovered` is read-only).
    property bool hovering: fieldHover.hovered
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

    HoverHandler {
        id: fieldHover

        cursorShape: Qt.IBeamCursor
    }

    Config.Theme {
        id: theme
    }

    background: Rectangle {
        radius: control.appearance.radius
        color: control.hovering ? theme.surfaceHover : "transparent"
        border.color: control.activeFocus || control.hovering ? theme.accent : theme.border
        border.width: 1

        Behavior on color {
            ColorAnimation { duration: control.appearance.motion.short }
        }

        Behavior on border.color {
            ColorAnimation { duration: control.appearance.motion.short }
        }
    }
}
