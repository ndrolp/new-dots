import QtQuick
import "../../config" as Config
import "." as Panels

// Secondary text beside a setting, a hint or a value: muted and a little
// smaller.
Panels.Text {
    required property var appearance

    color: theme.textMuted
    wrapMode: Text.WordWrap
    font.pixelSize: appearance.textSize - 1

    Config.Theme {
        id: theme
    }
}
