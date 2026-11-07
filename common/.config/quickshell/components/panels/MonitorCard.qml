import QtQuick
import "../../config" as Config
import "." as Panels

// What the cards about monitors share: the frame, a title and a line under it, then whatever each one
// asks. modules/MonitorChange.qml and MonitorToast.qml put them on the screens.
Rectangle {
    id: card

    required property var appearance
    property string title: ""
    property string hint: ""
    // Goes under the hint, as wide as it.
    default property alias content: column.data

    implicitWidth: 340
    implicitHeight: column.implicitHeight + 32
    width: implicitWidth
    height: implicitHeight
    radius: appearance.radius
    color: theme.surface
    border.color: theme.border
    border.width: 1

    Config.Theme {
        id: theme
    }

    Column {
        id: column

        anchors.centerIn: parent
        width: parent.width - 32
        spacing: 10

        Panels.Text {
            width: parent.width
            text: card.title
            color: theme.text
            font.pixelSize: card.appearance.textSize + 1
        }

        Panels.SettingsHint {
            objectName: "card hint"
            width: parent.width
            appearance: card.appearance
            text: card.hint
        }
    }
}
