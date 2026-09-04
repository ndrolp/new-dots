import Quickshell
import QtQuick
import QtQuick.Effects
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
    readonly property bool statusIslandEnabled: appearance.statusIsland
    readonly property real statusIslandGap: appearance.spacing
    readonly property real leftIslandGroupWidth: archButton.width + systemMonitor.width
        + currentApp.width + (statusIslandGap * 2)
    readonly property real islandSideSpacer: Math.max(leftIslandGroupWidth, statusModules.width)
    readonly property real workspaceIslandSpacer: statusIslandGap * 3
    readonly property real leftWorkspaceSpacer: workspaceIslandSpacer
        + islandSideSpacer - leftIslandGroupWidth
    readonly property real rightWorkspaceSpacer: workspaceIslandSpacer
        + islandSideSpacer - statusModules.width

    function popupTrigger(popup) {
        if (popup === "system")
            return systemMonitor;

        const trigger = statusModules.popupTrigger(popup);
        return trigger ? {
            x: statusModules.x + trigger.x,
            width: trigger.width
        } : null;
    }

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
            && !root.statusIslandEnabled
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
            && !root.statusIslandEnabled
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
            && !root.statusIslandEnabled
        appearance: root.appearance
        fillColor: theme.surface
        keepRightEdge: true
        z: -1
    }

    Rectangle {
        x: workspaces.x - root.leftWorkspaceSpacer - root.leftIslandGroupWidth
            - root.appearance.spacing
        y: 0
        width: workspaces.width + root.leftIslandGroupWidth + root.leftWorkspaceSpacer
            + root.rightWorkspaceSpacer + statusModules.width
            + (root.appearance.spacing * 2)
        height: parent.height
        radius: root.appearance.statusIslandRadius
        color: theme.backgroundSecondary
        visible: root.statusIslandEnabled
        z: -1

        layer.enabled: visible
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: "#80000000"
            shadowBlur: 0.45
            shadowVerticalOffset: 3
        }

        Behavior on x {
            NumberAnimation {
                duration: 180
                easing.type: Easing.OutCubic
            }
        }

        Behavior on width {
            NumberAnimation {
                duration: 180
                easing.type: Easing.OutCubic
            }
        }
    }

    ArchButton {
        id: archButton

        anchors.verticalCenter: parent.verticalCenter
        x: root.statusIslandEnabled
            ? workspaces.x - root.leftWorkspaceSpacer - root.leftIslandGroupWidth
            : root.appearance.barTransparent && root.appearance.transparentBarSlanted
                ? root.appearance.horizontalPadding : 0
        Behavior on x {
            NumberAnimation {
                duration: 220
                easing.type: Easing.OutCubic
            }
        }
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
        anchors.verticalCenter: parent.verticalCenter
        x: Math.round((parent.width - width) / 2)
        Behavior on x {
            NumberAnimation {
                duration: 220
                easing.type: Easing.OutCubic
            }
        }
        appearance: root.appearance
        monitorScreen: root.monitorScreen
        monitors: root.monitors
        workspaceService: root.workspaceService
    }

    StatusModules {
        id: statusModules
        anchors.verticalCenter: parent.verticalCenter
        x: root.statusIslandEnabled
            ? workspaces.x + workspaces.width + root.rightWorkspaceSpacer
            : parent.width - width - (root.appearance.barTransparent
                && root.appearance.transparentBarSlanted ? root.appearance.horizontalPadding : 0)
        Behavior on x {
            NumberAnimation {
                duration: 220
                easing.type: Easing.OutCubic
            }
        }
        appearance: root.appearance
        activePopup: root.activeStatusPopup
        monitorScreen: root.monitorScreen
        pomodoro: root.pomodoro

        onPopupRequested: function(popup) {
            root.statusPopupRequested(popup);
        }
    }
}
