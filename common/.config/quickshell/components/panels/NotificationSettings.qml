import QtQuick
import QtQuick.Controls
import "../../config" as Config

// Global notification settings (not part of any bar profile).
Column {
    id: root

    property var appearance

    width: parent ? parent.width : 0
    spacing: 12

    Config.Theme {
        id: theme
    }

    Rectangle {
        width: parent.width
        height: 44
        radius: root.appearance.radius
        color: notificationLocationHover.hovered ? theme.surfaceHover : theme.backgroundSecondary

        Behavior on color {
            ColorAnimation { duration: 140 }
        }

        HoverHandler {
            id: notificationLocationHover
        }

        Text {
            anchors.left: parent.left
            anchors.leftMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            text: "NOTIFICATION LOCATION"
            color: theme.text
            font.pixelSize: root.appearance.textSize - 1
            font.bold: true
        }

        ComboBox {
            id: notificationLocationSelector

            anchors.right: parent.right
            anchors.rightMargin: 6
            anchors.verticalCenter: parent.verticalCenter
            width: 168
            height: 32
            textRole: "label"
            model: [
                { label: "Top left", value: "top-left" },
                { label: "Top center", value: "top-center" },
                { label: "Top right", value: "top-right" },
                { label: "Bottom left", value: "bottom-left" },
                { label: "Bottom center", value: "bottom-center" },
                { label: "Bottom right", value: "bottom-right" }
            ]
            currentIndex: {
                for (let index = 0; index < model.length; index++) {
                    if (model[index].value === root.appearance.notificationPopupLocation)
                        return index;
                }

                return 1;
            }

            contentItem: Text {
                leftPadding: 10
                rightPadding: 30
                verticalAlignment: Text.AlignVCenter
                text: notificationLocationSelector.displayText
                color: theme.accent
                elide: Text.ElideRight
                font.pixelSize: root.appearance.textSize - 1
                font.bold: true
            }

            indicator: Text {
                anchors.right: parent.right
                anchors.rightMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                text: "󰅂"
                color: theme.accent
                font.pixelSize: root.appearance.textSize - 1
            }

            background: Rectangle {
                radius: root.appearance.radius
                color: theme.surface
            }

            onActivated: root.appearance.notificationPopupLocation = model[index].value
        }
    }
}
