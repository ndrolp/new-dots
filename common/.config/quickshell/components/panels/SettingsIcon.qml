import QtQuick
import "../../config" as Config
import "." as Panels

// The glyph before a setting's name, muted and in a fixed-width slot so the
// names after it line up. With no glyph it takes no room.
Panels.ShellText {
    required property var appearance

    visible: text !== ""
    width: visible ? Math.round(appearance.textSize * 1.4) : 0
    horizontalAlignment: Text.AlignHCenter
    color: theme.textMuted
    font.pixelSize: appearance.textSize

    Config.Theme {
        id: theme
    }
}
