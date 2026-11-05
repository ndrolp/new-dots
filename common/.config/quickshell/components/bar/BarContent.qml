import Quickshell
import QtQuick
import QtQuick.Effects
import "../../config" as Config
import "../../config/BarProfileModel.js" as BarProfileModel
import "BarElementItems.js" as BarElementItemsModel
import "BarLayout.js" as BarLayout

Item {
    id: root

    required property var appearance
    property bool configOpen: false
    property string activePopup: ""
    required property var monitorScreen
    required property var monitors
    required property var pomodoro
    required property var notificationHistory
    required property var screenCapture
    required property var keepAwake
    // The app menu module (modules/AppMenu.qml).
    required property var appMenu
    // The screens other apps share (services/ScreenShares.qml).
    required property var screenShares
    required property var cava
    property bool barVisible: true
    // Where the open popup sits in the bar, as BarPopups reports it, or null.
    property var openPopup: null
    required property var systemMonitor
    required property var workspaceService

    // The menu the app menu's Popup shows (AppMenuPopup.menuId).
    readonly property string appMenuId: appMenuElement.menuId

    signal configRequested(var screen)
    signal popupRequested(string popup)
    // A bar element that opens no popup was pressed.
    signal popupCloseRequested()
    readonly property var zoneNames: ["left", "center", "right"]
    // The docked bar's zones match an attached popup's color and opacity.
    readonly property color dockedColor: Qt.rgba(theme.background.r, theme.background.g,
        theme.background.b, appearance.barOpacity / 100)
    readonly property real dockedPadding: appearance.barTransparent && appearance.transparentBarSlanted
        ? appearance.horizontalPadding : 0
    // Room between a group's shared background and its first and last element.
    readonly property real groupPadding: appearance.spacing
    // The bar as BarLayout measures it.
    readonly property var layoutBar: ({
        barPosition: appearance.barPosition,
        width: root.width,
        height: root.height,
        spacing: appearance.spacing,
        groupPadding: groupPadding,
        endPadding: dockedPadding
    })
    // Whether the bar runs from the top of the screen down.
    readonly property bool vertical: BarLayout.vertical(layoutBar)

    // The item of every bar element, by element id.
    readonly property var elementItems: Object.assign({
        "arch": archButton,
        "systemMonitor": systemMonitor,
        "currentApp": currentApp,
        "appMenu": appMenuElement,
        "workspaces": workspaces
    }, barElementItems.items)

    // Bar elements are drawn with one walk per zone, in the order the profile
    // lists them; enabled elements with nothing to show take no space.
    function elementItem(element) {
        return elementItems[element] || null;
    }

    function popupElement(popup) {
        return BarElementItemsModel.popupElement(popup);
    }

    function elementVisible(element) {
        return BarProfileModel.elementEnabled(appearance.barElements, element);
    }

    function elementShown(element) {
        const item = elementItem(element);
        return item !== null && item.visible && BarLayout.itemLength(layoutBar, item) > 0;
    }

    // Positions within a zone, relative to its start, and one background per
    // group of two or more shown elements.
    function zoneLayout(zone) {
        const groups = BarProfileModel.zoneGroups(appearance.barElements, zone,
            element => root.elementShown(element));
        return BarLayout.zone(layoutBar, groups, element => BarLayout.itemLength(layoutBar, elementItem(element)));
    }

    function zoneLength(zone) {
        return zoneLayout(zone).length;
    }

    function zoneStart(zone) {
        return BarLayout.zoneStart(layoutBar, zone, zoneLength(zone));
    }

    function zoneEnd(zone) {
        return zoneStart(zone) + zoneLength(zone);
    }

    function elementPosition(element) {
        const zone = BarProfileModel.elementZone(appearance.barElements, element);
        return zone === "" ? null : zoneLayout(zone).positions[element] || null;
    }

    // Where an element goes, { x, y }: at its place along the bar, centred
    // across it.
    function elementPlace(element) {
        const zone = BarProfileModel.elementZone(appearance.barElements, element);
        const position = elementPosition(element);
        return BarLayout.place(layoutBar, zoneStart(zone) + (position ? position.start : 0),
            elementItem(element) || { width: 0, height: 0 });
    }

    function elementX(element) {
        return elementPlace(element).x;
    }

    function elementY(element) {
        return elementPlace(element).y;
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

        // An element with several triggers (the app menu's titles) says
        // which part opened the popup.
        return BarLayout.trigger(item, item.popupTriggerArea || null);
    }

    // The open popup, when it hangs from this zone. A popup whose bar element
    // isn't shown hangs from the zone at its edge.
    function zonePopup(zone) {
        if (!openPopup)
            return null;

        const element = popupElement(openPopup.popup);
        const popupZone = elementShown(element)
            ? BarProfileModel.elementZone(appearance.barElements, element) : openPopup.edge;
        return popupZone === zone ? openPopup : null;
    }

    Config.Theme {
        id: theme
    }

    DockedSurface {
        id: leftSurface

        spanLeft: 0
        spanRight: root.zoneEnd("left") + leftSurface.sideWidth
        popup: root.zonePopup("left")
        motion: root.appearance.motion
        barPosition: root.appearance.barPosition
        thickness: leftSurface.side ? root.width : root.height
        visible: root.appearance.barTransparent && root.appearance.transparentBarSlanted
        fillColor: root.dockedColor
        keepLeftEdge: true
        z: -1
    }

    DockedSurface {
        id: centerSurface

        spanLeft: root.zoneStart("center") - centerSurface.sideWidth
        spanRight: root.zoneEnd("center") + centerSurface.sideWidth
        popup: root.zonePopup("center")
        motion: root.appearance.motion
        barPosition: root.appearance.barPosition
        thickness: centerSurface.side ? root.width : root.height
        visible: root.appearance.barTransparent && root.appearance.transparentBarSlanted
        fillColor: root.dockedColor
        z: -1
    }

    DockedSurface {
        id: rightSurface

        spanLeft: root.zoneStart("right") - rightSurface.sideWidth
        spanRight: root.width
        popup: root.zonePopup("right")
        motion: root.appearance.motion
        barPosition: root.appearance.barPosition
        thickness: rightSurface.side ? root.width : root.height
        visible: root.appearance.barTransparent && root.appearance.transparentBarSlanted
        fillColor: root.dockedColor
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
                        || { start: 0, length: 0 }
                    readonly property var rect: BarLayout.groupBackground(root.layoutBar,
                        root.zoneStart(zoneBackgrounds.modelData) + background.start, background.length)

                    x: rect.x
                    y: rect.y
                    width: rect.width
                    height: rect.height
                    radius: root.appearance.groupRadius
                    color: Qt.rgba(theme.surface.r, theme.surface.g, theme.surface.b,
                        theme.surface.a * root.appearance.barOpacity / 100)
                    border.width: root.appearance.barTransparentBorder ? 1 : 0
                    border.color: root.appearance.barTransparentBorder ? theme.border : "transparent"

                    // Only along the bar: across it, it follows the bar at once.
                    Behavior on x {
                        enabled: !root.vertical

                        NumberAnimation {
                            duration: root.appearance.motion.medium
                            easing.type: root.appearance.motion.easing
                        }
                    }

                    Behavior on y {
                        enabled: root.vertical

                        NumberAnimation {
                            duration: root.appearance.motion.medium
                            easing.type: root.appearance.motion.easing
                        }
                    }

                    Behavior on width {
                        enabled: !root.vertical

                        NumberAnimation {
                            duration: root.appearance.motion.medium
                            easing.type: root.appearance.motion.easing
                        }
                    }

                    Behavior on height {
                        enabled: root.vertical

                        NumberAnimation {
                            duration: root.appearance.motion.medium
                            easing.type: root.appearance.motion.easing
                        }
                    }
                }
            }
        }
    }

    ArchButton {
        id: archButton

        visible: root.elementVisible("arch")
        x: root.elementX("arch")
        y: root.elementY("arch")
        grouped: root.elementGrouped("arch")
        Behavior on x {
            enabled: !root.vertical

            NumberAnimation {
                duration: root.appearance.motion.long
                easing.type: root.appearance.motion.easing
            }
        }
        Behavior on y {
            enabled: root.vertical

            NumberAnimation {
                duration: root.appearance.motion.long
                easing.type: root.appearance.motion.easing
            }
        }
        appearance: root.appearance
        active: root.configOpen
        onClicked: root.configRequested(root.monitorScreen)
    }

    CurrentApp {
        id: currentApp

        x: root.elementX("currentApp")
        y: root.elementY("currentApp")
        grouped: root.elementGrouped("currentApp")
        appearance: root.appearance
        monitorScreen: root.monitorScreen
        enabled: root.elementVisible("currentApp")
    }

    AppMenu {
        id: appMenuElement

        x: root.elementX("appMenu")
        y: root.elementY("appMenu")
        grouped: root.elementGrouped("appMenu")
        appearance: root.appearance
        monitorScreen: root.monitorScreen
        appMenu: root.appMenu
        enabled: root.elementVisible("appMenu")
        popupOpen: root.activePopup === "appMenu"
        onPopupRequested: root.popupRequested("appMenu")
    }

    SystemMonitor {
        id: systemMonitor

        visible: root.elementVisible("systemMonitor")
        x: root.elementX("systemMonitor")
        y: root.elementY("systemMonitor")
        grouped: root.elementGrouped("systemMonitor")
        appearance: root.appearance
        systemMonitor: root.systemMonitor
        onClicked: root.popupRequested("system")
    }

    Workspaces {
        id: workspaces
        visible: root.elementVisible("workspaces")
        x: root.elementX("workspaces")
        y: root.elementY("workspaces")
        grouped: root.elementGrouped("workspaces")
        Behavior on x {
            enabled: !root.vertical

            NumberAnimation {
                duration: root.appearance.motion.long
                easing.type: root.appearance.motion.easing
            }
        }
        Behavior on y {
            enabled: root.vertical

            NumberAnimation {
                duration: root.appearance.motion.long
                easing.type: root.appearance.motion.easing
            }
        }
        appearance: root.appearance
        monitorScreen: root.monitorScreen
        monitors: root.monitors
        workspaceService: root.workspaceService
    }

    BarElementItems {
        id: barElementItems

        anchors.fill: parent
        appearance: root.appearance
        activePopup: root.activePopup
        monitorScreen: root.monitorScreen
        pomodoro: root.pomodoro
        notificationHistory: root.notificationHistory
        screenCapture: root.screenCapture
        keepAwake: root.keepAwake
        screenShares: root.screenShares
        cava: root.cava
        barVisible: root.barVisible
        elementX: element => root.elementX(element)
        elementY: element => root.elementY(element)
        elementGrouped: element => root.elementGrouped(element)

        onPopupRequested: function(popup) {
            root.popupRequested(popup);
        }
    }

    BarPopupCloser {
        elementItems: root.elementItems
        onCloseRequested: root.popupCloseRequested()
    }
}
