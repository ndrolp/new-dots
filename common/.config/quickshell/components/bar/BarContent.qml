import Quickshell
import QtQuick
import QtQuick.Effects
import "../../config" as Config
import "../../config/BarProfileModel.js" as BarProfileModel

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
    readonly property var zoneNames: ["left", "center", "right"]
    readonly property real slantedPadding: appearance.barTransparent && appearance.transparentBarSlanted
        ? appearance.horizontalPadding : 0

    // Bar elements are drawn with one walk per zone, in the order the profile
    // lists them; enabled elements with nothing to show take no space.
    function elementItem(element) {
        if (element === "arch")
            return archButton;
        if (element === "systemMonitor")
            return systemMonitor;
        if (element === "currentApp")
            return currentApp;
        if (element === "workspaces")
            return workspaces;
        return statusModules.moduleItem(element);
    }

    function elementVisible(element) {
        return BarProfileModel.elementEnabled(appearance.barElements, element);
    }

    function zoneItems(zone) {
        const elements = (appearance.barElements || {})[zone] || [];
        const shown = [];

        for (let index = 0; index < elements.length; index++) {
            const element = elements[index].id;
            const item = elementItem(element);
            if (elements[index].enabled !== false && item && item.visible && item.width > 0)
                shown.push(element);
        }

        return shown;
    }

    function elementGap(previous, element) {
        return statusModules.moduleGap(previous, element);
    }

    function zoneWidth(zone) {
        const shown = zoneItems(zone);
        let width = 0;

        for (let index = 0; index < shown.length; index++) {
            if (index > 0)
                width += elementGap(shown[index - 1], shown[index]);
            width += elementItem(shown[index]).width;
        }

        return width;
    }

    function statusIslandContentWidth() {
        let width = 0;

        for (let index = 0; index < zoneNames.length; index++) {
            const nextWidth = zoneWidth(zoneNames[index]);
            if (nextWidth > 0)
                width += nextWidth + (width > 0 ? appearance.spacing : 0);
        }

        return width;
    }

    function statusIslandZoneStart(zone) {
        let x = Math.round((root.width - statusIslandContentWidth()) / 2);

        for (let index = 0; index < zoneNames.length; index++) {
            const candidate = zoneNames[index];
            const candidateWidth = zoneWidth(candidate);

            if (candidate === zone)
                return x;
            if (candidateWidth > 0)
                x += candidateWidth + (zoneWidth(zone) > 0 ? appearance.spacing : 0);
        }

        return x;
    }

    function zoneStart(zone) {
        if (statusIslandEnabled)
            return statusIslandZoneStart(zone);
        if (zone === "left")
            return slantedPadding;
        if (zone === "right")
            return root.width - zoneWidth("right") - slantedPadding;
        return Math.round((root.width - zoneWidth("center")) / 2);
    }

    function zoneEnd(zone) {
        return zoneStart(zone) + zoneWidth(zone);
    }

    function elementX(element) {
        const zone = BarProfileModel.elementZone(appearance.barElements, element);
        const shown = zoneItems(zone);
        let x = zoneStart(zone);

        for (let index = 0; index < shown.length; index++) {
            if (index > 0)
                x += elementGap(shown[index - 1], shown[index]);
            if (shown[index] === element)
                return x;
            x += elementItem(shown[index]).width;
        }

        return x;
    }

    function statusIslandLeft() {
        let left = root.width;

        for (let index = 0; index < zoneNames.length; index++) {
            if (zoneWidth(zoneNames[index]) > 0)
                left = Math.min(left, zoneStart(zoneNames[index]));
        }

        return Math.max(0, left - appearance.spacing);
    }

    function statusIslandRight() {
        let right = 0;

        for (let index = 0; index < zoneNames.length; index++) {
            if (zoneWidth(zoneNames[index]) > 0)
                right = Math.max(right, zoneEnd(zoneNames[index]));
        }

        return Math.min(root.width, right + appearance.spacing);
    }

    function popupTrigger(popup) {
        if (popup === "system")
            return systemMonitor;

        const trigger = statusModules.popupTrigger(popup);
        return trigger ? { x: statusModules.x + trigger.x, width: trigger.width } : null;
    }

    Config.Theme {
        id: theme
    }

    SlantedSurface {
        id: leftSurface

        x: 0
        width: root.zoneEnd("left") + leftSurface.slant
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

        x: root.zoneStart("center") - centerSurface.slant
        width: root.zoneWidth("center") + centerSurface.slant * 2
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

        x: root.zoneStart("right") - rightSurface.slant
        width: root.width - x
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
        x: root.elementX("arch")
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
        x: root.elementX("currentApp")
        appearance: root.appearance
        monitorScreen: root.monitorScreen
        enabled: root.elementVisible("currentApp")
    }

    SystemMonitor {
        id: systemMonitor

        anchors.verticalCenter: parent.verticalCenter
        visible: root.elementVisible("systemMonitor")
        x: root.elementX("systemMonitor")
        appearance: root.appearance
        systemMonitor: root.systemMonitor
        onClicked: root.statusPopupRequested("system")
    }

    Workspaces {
        id: workspaces
        anchors.verticalCenter: parent.verticalCenter
        visible: root.elementVisible("workspaces")
        x: root.elementX("workspaces")
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

        x: 0
        width: root.width
        anchors.verticalCenter: parent.verticalCenter
        appearance: root.appearance
        activePopup: root.activeStatusPopup
        monitorScreen: root.monitorScreen
        pomodoro: root.pomodoro
        notificationHistory: root.notificationHistory
        screenCapture: root.screenCapture
        elementX: element => root.elementX(element)

        onPopupRequested: function(popup) {
            root.statusPopupRequested(popup);
        }

        onNotificationRequested: root.notificationRequested()
    }
}
