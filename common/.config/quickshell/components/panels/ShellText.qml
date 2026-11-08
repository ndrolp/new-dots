import QtQuick as QtQuick
import "../../config/Font.js" as Font

// Text in the shell's font (Font.family). Use it instead of Text: a plain
// Text takes Qt's default font, and a file named Text.qml here would lose to
// QtQuick's own Text.
QtQuick.Text {
    font.family: Font.family
}
