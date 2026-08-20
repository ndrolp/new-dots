import Quickshell
import Quickshell.Hyprland
import QtQuick
import "../../config" as Config

Row {
    id: root

    required property var appearance

    readonly property var rawActiveToplevel: Hyprland.activeToplevel
    readonly property var activeToplevel: rawActiveToplevel
        && rawActiveToplevel.workspace
        && Hyprland.focusedWorkspace
        && rawActiveToplevel.workspace.id === Hyprland.focusedWorkspace.id
        ? rawActiveToplevel : null
    readonly property string appId: activeToplevel && activeToplevel.wayland
        ? activeToplevel.wayland.appId : ""
    readonly property string label: appId !== "" ? appId
        : activeToplevel ? activeToplevel.title : "Desktop"
    readonly property string iconSource: appId !== ""
        ? Quickshell.iconPath(appId, true) : ""

    spacing: appearance.spacing
    visible: label !== ""

    Config.Theme {
        id: theme
    }

    Behavior on width {
        NumberAnimation {
            duration: 180
            easing.type: Easing.OutCubic
        }
    }

    Rectangle {
        width: appContent.implicitWidth + 16
        height: appearance.workspaceButtonSize
        radius: appearance.radius
        color: appHover.hovered ? theme.surfaceHover : theme.surface

        Behavior on color {
            ColorAnimation {
                duration: 140
            }
        }

        HoverHandler {
            id: appHover
        }

        Row {
            id: appContent

            anchors.centerIn: parent
            spacing: root.appearance.spacing

            Item {
                id: icon

                property string displayedIconSource: root.iconSource

                visible: root.activeToplevel !== null
                width: visible ? root.appearance.workspaceButtonSize - 8 : 0
                height: appName.implicitHeight

                transform: Translate {
                    id: iconTranslation
                }

                Image {
                    anchors.centerIn: parent
                    width: icon.width
                    height: icon.width
                    source: icon.displayedIconSource
                    fillMode: Image.PreserveAspectFit
                    visible: icon.displayedIconSource !== ""
                }

                Text {
                    anchors.fill: parent
                    visible: icon.displayedIconSource === ""
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    text: "󰣆"
                    color: theme.green
                    font.pixelSize: appearance.textSize + 1
                    font.bold: true
                }
            }

            Text {
                id: appName

                property string displayedLabel: root.label

                anchors.verticalCenter: parent.verticalCenter
                text: displayedLabel
                color: theme.text
                font.pixelSize: appearance.textSize
                font.bold: true

                transform: Translate {
                    id: labelTranslation
                }
            }
        }
    }

    SequentialAnimation {
        id: labelTransition

        ParallelAnimation {
            NumberAnimation {
                target: labelTranslation
                property: "x"
                to: -12
                duration: 90
            }

            NumberAnimation {
                target: iconTranslation
                property: "x"
                to: -12
                duration: 90
            }
        }

        ScriptAction {
            script: {
                appName.displayedLabel = root.label;
                icon.displayedIconSource = root.iconSource;
                labelTranslation.x = 12;
                iconTranslation.x = 12;
            }
        }

        ParallelAnimation {
            NumberAnimation {
                target: labelTranslation
                property: "x"
                to: 0
                duration: 160
                easing.type: Easing.OutCubic
            }

            NumberAnimation {
                target: iconTranslation
                property: "x"
                to: 0
                duration: 160
                easing.type: Easing.OutCubic
            }
        }
    }

    onLabelChanged: labelTransition.restart()
}
