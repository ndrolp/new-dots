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
    required property var notificationHistory
    required property var screenCapture
    required property var systemMonitor
    required property var workspaceService

    signal configRequested(var screen)
    signal statusPopupRequested(string popup)
    signal notificationRequested()
    readonly property bool statusIslandEnabled: appearance.statusIsland
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

    function statusZoneWidth(zone) {
        if (zone === "left")
            return leftStatusModules.width;
        if (zone === "center")
            return centerStatusModules.width;
        return statusModules.width;
    }

    function zoneWidth(zone) {
        const structuralWidth = structuralZoneWidth(zone);
        const modulesWidth = statusZoneWidth(zone);
        return structuralWidth + modulesWidth
            + (structuralWidth > 0 && modulesWidth > 0 ? appearance.spacing : 0);
    }

    function statusIslandContentWidth() {
        const zones = ["left", "center", "right"];
        let width = 0;

        for (let index = 0; index < zones.length; index++) {
            const nextWidth = zoneWidth(zones[index]);
            if (nextWidth > 0)
                width += nextWidth + (width > 0 ? appearance.spacing : 0);
        }

        return width;
    }

    function statusIslandZoneStart(zone) {
        const zones = ["left", "center", "right"];
        let x = Math.round((root.width - statusIslandContentWidth()) / 2);

        for (let index = 0; index < zones.length; index++) {
            const candidate = zones[index];
            const candidateWidth = zoneWidth(candidate);

            if (candidate === zone)
                return x;
            if (candidateWidth > 0)
                x += candidateWidth + (zoneWidth(zone) > 0 ? appearance.spacing : 0);
        }

        return x;
    }

    function statusZoneX(zone, modules) {
        const structuralWidth = structuralZoneWidth(zone);
        const gap = structuralWidth > 0 && modules.width > 0 ? appearance.spacing : 0;

        if (statusIslandEnabled)
            return statusIslandZoneStart(zone) + structuralWidth + gap;

        const padding = appearance.barTransparent && appearance.transparentBarSlanted
            ? appearance.horizontalPadding : 0;

        if (zone === "right")
            return root.width - modules.width - padding;

        const start = zone === "left" ? padding
            : Math.round((root.width - structuralWidth - gap - modules.width) / 2);
        return start + structuralWidth + gap;
    }

    function structuralX(element) {
        const zone = elementPlacement(element);

        if (statusIslandEnabled) {
            let x = statusIslandZoneStart(zone);

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

    function statusIslandLeft() {
        const items = [
            archButton, systemMonitor, currentApp, workspaces,
            leftStatusModules, centerStatusModules, statusModules
        ];
        let left = root.width;

        for (let index = 0; index < items.length; index++) {
            const item = items[index];
            if (item.visible && item.width > 0)
                left = Math.min(left, item.x);
        }

        return Math.max(0, left - appearance.spacing);
    }

    function statusIslandRight() {
        const items = [
            archButton, systemMonitor, currentApp, workspaces,
            leftStatusModules, centerStatusModules, statusModules
        ];
        let right = 0;

        for (let index = 0; index < items.length; index++) {
            const item = items[index];
            if (item.visible && item.width > 0)
                right = Math.max(right, item.x + item.width);
        }

        return Math.min(root.width, right + appearance.spacing);
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
        x: root.statusIslandLeft()
        y: 0
        width: Math.max(0, root.statusIslandRight() - x)
        height: parent.height
        radius: root.appearance.statusIslandRadius
        color: theme.surface
        border.width: root.appearance.barTransparentBorder ? 1 : 0
        border.color: root.appearance.barTransparentBorder ? theme.border : "transparent"
        visible: root.statusIslandEnabled
        z: -1

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
        notificationHistory: root.notificationHistory
        screenCapture: root.screenCapture
        placement: "left"

        onPopupRequested: function(popup) {
            root.statusPopupRequested(popup);
        }

        onNotificationRequested: root.notificationRequested()
    }

    StatusModules {
        id: centerStatusModules

        anchors.verticalCenter: parent.verticalCenter
        x: root.statusZoneX("center", centerStatusModules)
        appearance: root.appearance
        activePopup: root.activeStatusPopup
        monitorScreen: root.monitorScreen
        pomodoro: root.pomodoro
        notificationHistory: root.notificationHistory
        screenCapture: root.screenCapture
        placement: "center"

        onPopupRequested: function(popup) {
            root.statusPopupRequested(popup);
        }

        onNotificationRequested: root.notificationRequested()
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
        notificationHistory: root.notificationHistory
        screenCapture: root.screenCapture
        placement: "right"

        onPopupRequested: function(popup) {
            root.statusPopupRequested(popup);
        }

        onNotificationRequested: root.notificationRequested()
    }
}
