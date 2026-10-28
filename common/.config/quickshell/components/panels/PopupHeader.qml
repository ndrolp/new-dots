import QtQuick
import "../../config" as Config
import "." as Panels

// A popup's title with its icon, a muted subtitle, and room on the right,
// e.g. for a switch.
Item {
    id: header

    required property var appearance
    property string icon: ""
    property color iconColor: theme.textMuted
    property string title: ""
    property string subtitle: ""
    default property alias trailing: trailingSlot.data

    width: parent ? parent.width : 0
    implicitHeight: Math.max(headerText.implicitHeight, trailingSlot.height)

    Config.Theme {
        id: theme
    }

    Panels.Text {
        id: headerIcon

        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        visible: header.icon !== ""
        text: header.icon
        color: header.iconColor
        font.pixelSize: header.appearance.textSize + 5

        Behavior on color {
            ColorAnimation { duration: header.appearance.motion.short }
        }
    }

    Column {
        id: headerText

        anchors.left: headerIcon.visible ? headerIcon.right : parent.left
        anchors.leftMargin: headerIcon.visible ? 10 : 0
        anchors.right: trailingSlot.left
        anchors.rightMargin: trailingSlot.width > 0 ? 8 : 0
        anchors.verticalCenter: parent.verticalCenter
        spacing: 1

        PopupTitle {
            width: parent.width
            appearance: header.appearance
            text: header.title
        }

        PopupLabel {
            width: parent.width
            appearance: header.appearance
            visible: header.subtitle !== ""
            text: header.subtitle
        }
    }

    Item {
        id: trailingSlot

        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        width: childrenRect.width
        height: childrenRect.height
    }
}
