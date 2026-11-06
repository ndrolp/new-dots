import QtQuick
import "../../config" as Config
import "WorkspaceOverview.js" as WorkspaceOverview

// The heading over a monitor's workspaces: its name, and the button that adds a
// workspace while it can.
Item {
    id: root

    required property var appearance
    required property string monitorName
    required property bool canAddWorkspace

    signal addWorkspaceRequested()

    height: WorkspaceOverview.spacing.header

    Config.Theme {
        id: theme
    }

    Text {
        anchors.left: parent.left
        anchors.right: addWorkspaceButton.visible ? addWorkspaceButton.left : parent.right
        anchors.verticalCenter: parent.verticalCenter
        text: root.monitorName
        color: theme.text
        elide: Text.ElideRight
        font.pixelSize: root.appearance.textSize
        font.bold: true
    }

    Rectangle {
        id: addWorkspaceButton

        objectName: "addWorkspaceButton"
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        visible: root.canAddWorkspace
        width: 30
        height: 24
        radius: root.appearance.radius
        color: addWorkspaceHover.hovered ? theme.surfaceHover : theme.backgroundSecondary

        HoverHandler {
            id: addWorkspaceHover
        }

        Text {
            anchors.centerIn: parent
            text: "+"
            color: theme.accent
            font.pixelSize: root.appearance.textSize + 2
            font.bold: true
        }

        MouseArea {
            anchors.fill: parent
            onClicked: root.addWorkspaceRequested()
        }
    }
}
