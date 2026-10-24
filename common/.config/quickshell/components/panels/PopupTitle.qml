import QtQuick
import "../../config" as Config
import "." as Panels

// The only bold text in a popup.
Panels.Text {
    required property var appearance

    color: theme.text
    elide: Text.ElideRight
    font.pixelSize: appearance.textSize + 1
    font.bold: true

    Config.Theme {
        id: theme
    }
}
