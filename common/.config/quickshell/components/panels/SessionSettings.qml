import Quickshell.Io
import QtQuick
import "../../config" as Config

Column {
    id: root

    property var appearance

    width: parent ? parent.width : 0
    spacing: 12

    Config.Theme {
        id: theme
    }

    Process {
        id: sessionAction
    }

    Text {
        width: parent.width
        text: "Hypridle locks after 10 minutes, turns displays off after 10.5 minutes, and suspends after 30 minutes."
        wrapMode: Text.WordWrap
        color: theme.textMuted
        font.pixelSize: root.appearance.textSize - 1
    }

    Repeater {
        model: [
            {
                label: "LOCK NOW",
                description: "Lock this session with Hyprlock.",
                icon: "󰌾",
                command: ["loginctl", "lock-session"]
            },
            {
                label: "TURN DISPLAYS OFF",
                description: "Turn displays off until the next input.",
                icon: "󰍹",
                command: ["hyprctl", "dispatch", "dpms", "off"]
            },
            {
                label: "SUSPEND",
                description: "Lock and suspend the computer.",
                icon: "󰤄",
                command: ["systemctl", "suspend"]
            }
        ]

        delegate: Rectangle {
            id: actionCard

            required property var modelData

            width: parent.width
            height: 62
            radius: root.appearance.radius
            color: actionHover.hovered ? theme.surfaceHover : theme.backgroundSecondary

            Behavior on color {
                ColorAnimation { duration: 140 }
            }

            HoverHandler {
                id: actionHover
            }

            Text {
                anchors.left: parent.left
                anchors.leftMargin: 14
                anchors.verticalCenter: parent.verticalCenter
                text: actionCard.modelData.icon
                color: theme.accent
                font.pixelSize: 20
            }

            Column {
                anchors.left: parent.left
                anchors.leftMargin: 50
                anchors.right: parent.right
                anchors.rightMargin: 14
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2

                Text {
                    text: actionCard.modelData.label
                    color: theme.text
                    font.pixelSize: root.appearance.textSize - 1
                    font.bold: true
                }

                Text {
                    width: parent.width
                    text: actionCard.modelData.description
                    color: theme.textMuted
                    elide: Text.ElideRight
                    font.pixelSize: root.appearance.textSize - 2
                }
            }

            TapHandler {
                onTapped: {
                    sessionAction.command = actionCard.modelData.command;
                    sessionAction.running = true;
                }
            }
        }
    }
}
