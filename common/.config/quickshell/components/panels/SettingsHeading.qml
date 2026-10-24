import QtQuick
import "../../config" as Config
import "." as Panels

// A group heading inside a section: small, muted, uppercase.
Panels.Text {
    required property var appearance

    color: theme.textMuted
    elide: Text.ElideRight
    font.pixelSize: appearance.textSize - 2
    font.capitalization: Font.AllUppercase
    font.letterSpacing: 0.5

    Config.Theme {
        id: theme
    }
}
