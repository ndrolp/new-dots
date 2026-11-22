import QtQuick

// The hover every settings control that answers the pointer shares:
// `hovering` follows the pointer (settable, so its look can be checked
// without one), the pointer takes `cursorShape` over it (a pointing hand
// unless set), and its fill eases between colours with the motion tokens.
// What it fills with, hovered or not, is the control's own.
Rectangle {
    id: fill

    required property var appearance
    property bool hovering: pointer.hovered
    property alias cursorShape: pointer.cursorShape

    Behavior on color {
        ColorAnimation { duration: fill.appearance.motion.short }
    }

    HoverHandler {
        id: pointer

        cursorShape: Qt.PointingHandCursor
    }
}
