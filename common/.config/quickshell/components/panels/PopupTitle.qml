import QtQuick
import "../../config" as Config

// The only bold text in a popup.
Text {
    required property var appearance

    color: theme.text
    elide: Text.ElideRight
    font.pixelSize: appearance.textSize + 1
    font.bold: true

    Config.Theme {
        id: theme
    }
}
