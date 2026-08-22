import QtQuick as QtQuick
import "../../config" as Config

QtQuick.Text {
    Config.Theme {
        id: theme
    }

    font.family: theme.fontFamily
}
