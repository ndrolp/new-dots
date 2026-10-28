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
    required property var keepAwake
    required property var cava
    property bool barVisible: true
    required property var systemMonitor
    required property var workspaceService

    signal configRequested(var screen)
    signal statusPopupRequested(string popup)
    signal notificationRequested()
    readonly property var zoneNames: ["left", "center", "right"]
    readonly property real slantedPadding: appearance.barTransparent && appearance.transparentBarSlanted
        ? appearance.horizontalPadding : 0
    // Room between a group's shared background and its first and last element.
    readonly property real groupPadding: appearance.spacing

    // The item of every bar element, by element id.
    readonly property var elementItems: Object.assign({
        "arch": archButton,
        "systemMonitor": systemMonitor,
        "currentApp": currentApp,
        "workspaces": workspaces
    }, barElementItems.items)

    // The bar element each popup opens from, when its name differs.
    readonly property var popupElements: ({
        "system": "systemMonitor",
        "pomodoro": "clock"
    })

    // Bar elements are drawn with one walk per zone, in the order the profile
    // lists them; enabled elements with nothing to show take no space.
    function elementItem(element) {
        return elementItems[element] || null;
    }

    function popupElement(popup) {
        return popupElements[popup] || popup;
    }

    function elementVisible(element) {
        return BarProfileModel.elementEnabled(appearance.barElements, element);
    }

    function elementShown(element) {
        const item = elementItem(element);
        return item !== null && item.visible && item.width > 0;
    }

    // Positions within a zone, relative to its start, and one background per
    // group of two or more shown elements.
    function zoneLayout(zone) {
        const groups = BarProfileModel.zoneGroups(appearance.barElements, zone,
            element => root.elementShown(element));
        const positions = {};
        const backgrounds = [];
        let x = 0;

        for (let groupIndex = 0; groupIndex < groups.length; groupIndex++) {
            const group = groups[groupIndex];
            const grouped = group.length > 1;
            const start = groupIndex > 0 ? x + appearance.spacing : 0;

            x = start + (grouped ? groupPadding : 0);
            for (let index = 0; index < group.length; index++) {
                if (index > 0)
                    x += appearance.spacing;
                positions[group[index]] = { x: x, grouped: grouped };
                x += elementItem(group[index]).width;
            }

            if (grouped) {
                x += groupPadding;
                backgrounds.push({ x: start, width: x - start });
            }
        }

        return { positions: positions, backgrounds: backgrounds, width: x };
    }

    function zoneWidth(zone) {
        return zoneLayout(zone).width;
    }

    function zoneStart(zone) {
        if (zone === "left")
            return slantedPadding;
        if (zone === "right")
            return root.width - zoneWidth("right") - slantedPadding;
        return Math.round((root.width - zoneWidth("center")) / 2);
    }

    function zoneEnd(zone) {
        return zoneStart(zone) + zoneWidth(zone);
    }

    function elementPosition(element) {
        const zone = BarProfileModel.elementZone(appearance.barElements, element);
        return zone === "" ? null : zoneLayout(zone).positions[element] || null;
    }

    function elementX(element) {
        const zone = BarProfileModel.elementZone(appearance.barElements, element);
        const position = elementPosition(element);
        return zoneStart(zone) + (position ? position.x : 0);
    }

    // Grouped elements drop their own pill: the group draws one background.
    function elementGrouped(element) {
        const position = elementPosition(element);
        return position !== null && position.grouped;
    }

    // Where the element a popup opens from sits in the bar; null when it isn't
    // shown, so the popup opens at the bar edge.
    function popupTrigger(popup) {
        const element = popupElement(popup);
        if (!elementShown(element))
            return null;

        const item = elementItem(element);

        const offset = item.parent === barElementItems ? barElementItems.x : 0;
        return { x: offset + item.x, width: item.width };
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
        appearance: root.appearance
        fillColor: theme.surface
        keepRightEdge: true
        z: -1
    }

    // One shared background per group.
    Repeater {
        model: root.zoneNames

        delegate: Item {
            id: zoneBackgrounds

            required property string modelData
            readonly property var backgrounds: root.zoneLayout(modelData).backgrounds

            anchors.fill: parent
            z: -1

            Repeater {
                model: zoneBackgrounds.backgrounds.length

                delegate: Rectangle {
                    required property int index
                    readonly property var background: zoneBackgrounds.backgrounds[index]
                        || { x: 0, width: 0 }

                    x: root.zoneStart(zoneBackgrounds.modelData) + background.x
                    y: 0
                    width: background.width
                    height: parent.height
                    radius: root.appearance.groupRadius
                    color: theme.surface
                    border.width: root.appearance.barTransparentBorder ? 1 : 0
                    border.color: root.appearance.barTransparentBorder ? theme.border : "transparent"

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
            }
        }
    }

    ArchButton {
        id: archButton

        anchors.verticalCenter: parent.verticalCenter
        visible: root.elementVisible("arch")
        x: root.elementX("arch")
        grouped: root.elementGrouped("arch")
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
        grouped: root.elementGrouped("currentApp")
        appearance: root.appearance
        monitorScreen: root.monitorScreen
        enabled: root.elementVisible("currentApp")
    }

    SystemMonitor {
        id: systemMonitor

        anchors.verticalCenter: parent.verticalCenter
        visible: root.elementVisible("systemMonitor")
        x: root.elementX("systemMonitor")
        grouped: root.elementGrouped("systemMonitor")
        appearance: root.appearance
        systemMonitor: root.systemMonitor
        onClicked: root.statusPopupRequested("system")
    }

    Workspaces {
        id: workspaces
        anchors.verticalCenter: parent.verticalCenter
        visible: root.elementVisible("workspaces")
        x: root.elementX("workspaces")
        grouped: root.elementGrouped("workspaces")
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

    BarElementItems {
        id: barElementItems

        x: 0
        width: root.width
        anchors.verticalCenter: parent.verticalCenter
        appearance: root.appearance
        activePopup: root.activeStatusPopup
        monitorScreen: root.monitorScreen
        pomodoro: root.pomodoro
        notificationHistory: root.notificationHistory
        screenCapture: root.screenCapture
        keepAwake: root.keepAwake
        cava: root.cava
        barVisible: root.barVisible
        elementX: element => root.elementX(element)
        elementGrouped: element => root.elementGrouped(element)

        onPopupRequested: function(popup) {
            root.statusPopupRequested(popup);
        }

        onNotificationRequested: root.notificationRequested()
    }
}
