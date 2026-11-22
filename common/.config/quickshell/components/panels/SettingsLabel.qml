import QtQuick
import "../../config" as Config
import "." as Panels

// A setting's name: sentence case, regular weight, normal text color. Longer
// than its width, it wraps to further lines; it never elides.
Panels.ShellText {
    required property var appearance

    color: theme.text
    wrapMode: Text.Wrap
    font.pixelSize: appearance.textSize

    Config.Theme {
        id: theme
    }
}
