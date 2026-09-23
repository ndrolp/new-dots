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
        + currentApp.width + leftStatusModules.width + (statusIslandGap * 3)
    readonly property real islandSideSpacer: Math.max(leftIslandGroupWidth, statusModules.width)
    readonly property real workspaceIslandSpacer: statusIslandGap * 3
    readonly property real leftWorkspaceSpacer: workspaceIslandSpacer
        + islandSideSpacer - leftIslandGroupWidth
    readonly property real rightWorkspaceSpacer: workspaceIslandSpacer
        + islandSideSpacer - statusModules.width
    readonly property real centerStatusGap: centerStatusModules.width > 0 ? appearance.spacing : 0
    readonly property real centeredContentWidth: workspaces.width + centerStatusGap
        + centerStatusModules.width
    readonly property var structuralOrder: ["arch", "system", "currentApp", "workspaces"]

    function elementPlacement(element) {
        const defaults = {
            "arch": "left",
            "system": "left",
            "currentApp": "left",
            "workspaces": "center"
        };
        return (appearance.barElementPlacement || {})[element] || defaults[element];
    }

    function elementVisible(element) {
        return (appearance.barElementEnabled || {})[element] !== false;
    }

    function elementWidth(element) {
        if (element === "arch")
            return archButton.width;
        if (element === "system")
            return systemMonitor.width;
        if (element === "currentApp")
            return currentApp.width;
        return workspaces.width;
    }

    function structuralZoneWidth(zone) {
        let width = 0;

        for (let index = 0; index < structuralOrder.length; index++) {
            const element = structuralOrder[index];
            if (elementVisible(element) && elementPlacement(element) === zone)
                width += elementWidth(element) + (width > 0 ? appearance.spacing : 0);
        }

        return width;
    }

    function statusZoneX(zone, modules) {
        const padding = appearance.barTransparent && appearance.transparentBarSlanted
            ? appearance.horizontalPadding : 0;

        if (zone === "right")
            return root.width - modules.width - padding;

        const structuralWidth = structuralZoneWidth(zone);
        const gap = structuralWidth > 0 && modules.width > 0 ? appearance.spacing : 0;
        const start = zone === "left" ? padding
            : Math.round((root.width - structuralWidth - gap - modules.width) / 2);
        return start + structuralWidth + gap;
    }

    function structuralX(element) {
        const zone = elementPlacement(element);
        const zoneModules = zone === "left" ? leftStatusModules : centerStatusModules;
        const padding = appearance.barTransparent && appearance.transparentBarSlanted
            ? appearance.horizontalPadding : 0;
        let x = zone === "right"
            ? root.width - statusModules.width - padding - structuralZoneWidth("right")
                - (statusModules.width > 0 && structuralZoneWidth("right") > 0 ? appearance.spacing : 0)
            : zone === "left" ? padding
                : Math.round((root.width - structuralZoneWidth("center")
                    - (centerStatusModules.width > 0 && structuralZoneWidth("center") > 0
                        ? appearance.spacing : 0) - centerStatusModules.width) / 2);

        for (let index = 0; index < structuralOrder.length; index++) {
            const candidate = structuralOrder[index];
            if (!elementVisible(candidate) || elementPlacement(candidate) !== zone)
                continue;
            if (candidate === element)
                return x;
            x += elementWidth(candidate) + appearance.spacing;
        }

        return x;
    }

    function popupTrigger(popup) {
        if (popup === "system")
            return systemMonitor;

        const modules = [leftStatusModules, centerStatusModules, statusModules];
        for (let index = 0; index < modules.length; index++) {
            const trigger = modules[index].popupTrigger(popup);
            if (trigger) {
                return {
                    x: modules[index].x + trigger.x,
                    width: trigger.width
                };
            }
        }

        return null;
    }

    Config.Theme {
        id: theme
    }

    SlantedSurface {
        id: leftSurface

        anchors.left: parent.left
        anchors.right: leftStatusModules.width > 0 ? leftStatusModules.right : currentApp.right
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
        anchors.right: centerStatusModules.width > 0 ? centerStatusModules.right : workspaces.right
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
            + root.centerStatusGap + centerStatusModules.width + root.rightWorkspaceSpacer
            + statusModules.width
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
        visible: root.elementVisible("arch")
        x: root.structuralX("arch")
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

        anchors.verticalCenter: parent.verticalCenter
        x: root.structuralX("currentApp")
        appearance: root.appearance
        monitorScreen: root.monitorScreen
        enabled: root.elementVisible("currentApp")
    }

    SystemMonitor {
        id: systemMonitor

        anchors.verticalCenter: parent.verticalCenter
        visible: root.elementVisible("system")
        x: root.structuralX("system")
        appearance: root.appearance
        systemMonitor: root.systemMonitor
        onClicked: root.statusPopupRequested("system")
    }

    Workspaces {
        id: workspaces
        anchors.verticalCenter: parent.verticalCenter
        visible: root.elementVisible("workspaces")
        x: root.structuralX("workspaces")
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
        id: leftStatusModules

        anchors.verticalCenter: parent.verticalCenter
        x: root.statusZoneX("left", leftStatusModules)
        appearance: root.appearance
        activePopup: root.activeStatusPopup
        monitorScreen: root.monitorScreen
        pomodoro: root.pomodoro
        placement: "left"

        onPopupRequested: function(popup) {
            root.statusPopupRequested(popup);
        }
    }

    StatusModules {
        id: centerStatusModules

        anchors.verticalCenter: parent.verticalCenter
        x: root.statusZoneX("center", centerStatusModules)
        appearance: root.appearance
        activePopup: root.activeStatusPopup
        monitorScreen: root.monitorScreen
        pomodoro: root.pomodoro
        placement: "center"

        onPopupRequested: function(popup) {
            root.statusPopupRequested(popup);
        }
    }

    StatusModules {
        id: statusModules
        anchors.verticalCenter: parent.verticalCenter
        x: root.statusZoneX("right", statusModules)
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
        placement: "right"

        onPopupRequested: function(popup) {
            root.statusPopupRequested(popup);
        }
    }
}
