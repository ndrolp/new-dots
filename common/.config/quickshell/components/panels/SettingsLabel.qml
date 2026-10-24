import QtQuick
import "../../config" as Config
import "." as Panels

// A setting's name: sentence case, regular weight, normal text color.
Panels.Text {
    required property var appearance

    color: theme.text
    elide: Text.ElideRight
    font.pixelSize: appearance.textSize

    Config.Theme {
        id: theme
    }
}
