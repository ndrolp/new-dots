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
    required property var pomodoro
    required property var systemMonitor
    required property var workspaceService

    signal configRequested(var screen)
    signal statusPopupRequested(string popup)

    Config.Theme {
        id: theme
    }

    SlantedSurface {
        id: leftSurface

        anchors.left: parent.left
        anchors.right: currentApp.right
        anchors.rightMargin: -leftSurface.slant
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        visible: root.appearance.barTransparent && root.appearance.transparentBarSlanted
        appearance: root.appearance
        fillColor: theme.surface
        keepLeftEdge: true
        z: -1
    }

    SlantedSurface {
        id: centerSurface

        anchors.left: workspaces.left
        anchors.leftMargin: -centerSurface.slant
        anchors.right: workspaces.right
        anchors.rightMargin: -centerSurface.slant
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        visible: root.appearance.barTransparent && root.appearance.transparentBarSlanted
        appearance: root.appearance
        fillColor: theme.surface
        slantBothSides: true
        z: -1
    }

    SlantedSurface {
        id: rightSurface

        anchors.left: statusModules.left
        anchors.leftMargin: -rightSurface.slant
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        visible: root.appearance.barTransparent && root.appearance.transparentBarSlanted
        appearance: root.appearance
        fillColor: theme.surface
        keepRightEdge: true
        z: -1
    }

    ArchButton {
        id: archButton

        anchors.left: parent.left
        anchors.leftMargin: root.appearance.barTransparent && root.appearance.transparentBarSlanted ? root.appearance.horizontalPadding : 0
        anchors.verticalCenter: parent.verticalCenter
        appearance: root.appearance
        active: root.configOpen
        onClicked: root.configRequested(root.monitorScreen)
    }

    CurrentApp {
        id: currentApp

        anchors.left: systemMonitor.right
        anchors.leftMargin: root.appearance.spacing
        anchors.verticalCenter: parent.verticalCenter
        appearance: root.appearance
        monitorScreen: root.monitorScreen
    }

    SystemMonitor {
        id: systemMonitor

        anchors.left: archButton.right
        anchors.leftMargin: root.appearance.spacing
        anchors.verticalCenter: parent.verticalCenter
        appearance: root.appearance
        systemMonitor: root.systemMonitor
        onClicked: root.statusPopupRequested("system")
    }

    Workspaces {
        id: workspaces
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        appearance: root.appearance
        monitorScreen: root.monitorScreen
        monitors: root.monitors
        workspaceService: root.workspaceService
    }

    StatusModules {
        id: statusModules
        anchors.right: parent.right
        anchors.rightMargin: root.appearance.barTransparent && root.appearance.transparentBarSlanted ? root.appearance.horizontalPadding : 0
        anchors.verticalCenter: parent.verticalCenter
        appearance: root.appearance
        activePopup: root.activeStatusPopup
        monitorScreen: root.monitorScreen
        pomodoro: root.pomodoro

        onPopupRequested: function(popup) {
            root.statusPopupRequested(popup);
        }
    }
}
