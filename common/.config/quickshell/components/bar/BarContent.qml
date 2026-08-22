import Quickshell
import QtQuick
import "../../config" as Config

Item {
    id: root

    required property var appearance
    property bool configOpen: false
    property string activeStatusPopup: ""
    required property var monitorScreen
    required property var monitors
    required property var workspaceService

    signal configRequested(var screen)
    signal statusPopupRequested(string popup)

    Config.Theme {
        id: theme
    }

    ArchButton {
        id: archButton

        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        appearance: root.appearance
        active: root.configOpen
        onClicked: root.configRequested(root.monitorScreen)
    }

    CurrentApp {
        anchors.left: archButton.right
        anchors.leftMargin: root.appearance.spacing
        anchors.verticalCenter: parent.verticalCenter
        appearance: root.appearance
        monitorScreen: root.monitorScreen
    }

    Workspaces {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        appearance: root.appearance
        monitorScreen: root.monitorScreen
        monitors: root.monitors
        workspaceService: root.workspaceService
    }

    StatusModules {
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        appearance: root.appearance
        activePopup: root.activeStatusPopup

        onPopupRequested: function(popup) {
            root.statusPopupRequested(popup);
        }
    }
}
