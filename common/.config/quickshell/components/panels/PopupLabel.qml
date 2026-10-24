import QtQuick
import "../../config" as Config
import "." as Panels

// Secondary text: regular weight, muted.
Panels.Text {
    required property var appearance

    color: theme.textMuted
    elide: Text.ElideRight
    font.pixelSize: appearance.textSize - 2

    Config.Theme {
        id: theme
    }
}
