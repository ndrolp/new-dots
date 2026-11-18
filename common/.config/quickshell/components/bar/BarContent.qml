import Quickshell
import QtQuick
import QtQuick.Effects
import "../BarPosition.js" as BarPosition
import "../../config" as Config
import "../../config/BarProfileModel.js" as BarProfileModel
import "BarElementItems.js" as BarElementItemsModel
import "BarLayout.js" as BarLayout
import "BarPlacement.js" as BarPlacement
import "CapsulePlacement.js" as CapsulePlacement

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
    // The change a capsule shows instead of its row (see CapsuleChange.qml),
    // or null while it shows none.
    property var capsuleChange: null
    // How long the capsule's workspace pills are along the bar.
    property real workspacePillsLength: 0

    // The menu the app menu's Popup shows (AppMenuPopup.menuId).
    readonly property string appMenuId: appMenuElement.menuId

    signal configRequested(var screen)
    signal popupRequested(string popup)
    // A bar element that opens no popup was pressed.
    signal popupCloseRequested()
    readonly property var zoneNames: ["left", "center", "right"]
    // The docked bar's zones match an attached popup's color and opacity; the
    // capsule takes the same, the profile's background at its opacity.
    readonly property color dockedColor: Qt.rgba(theme.background.r, theme.background.g,
        theme.background.b, appearance.barOpacity / 100)
    readonly property real dockedPadding: BarProfileModel.docked(appearance)
        ? appearance.horizontalPadding : 0
    // Room between a group's shared background and its first and last element.
    readonly property real groupPadding: appearance.groupHorizontalPadding
    // The bar as BarLayout measures it.
    readonly property var layoutBar: ({
        barPosition: appearance.barPosition,
        width: root.width,
        height: root.height,
        spacing: appearance.spacing,
        groupPadding: groupPadding,
        groupInset: appearance.groupVerticalPadding,
        endPadding: dockedPadding
    })
    // Whether the bar runs from the top of the screen down.
    readonly property bool sideBar: BarPosition.sideBar(appearance.barPosition)
    // On a capsule, the span along the bar of its row: the centre zone (see
    // CapsuleElements.drawnElements), or the change it shows instead.
    readonly property var rowSpan: capsuleChange !== null
        ? { start: changeStart, end: changeStart + changeView.width }
        : { start: zoneStart("center"), end: zoneEnd("center") }
    // The live elements beside a capsule's workspace pills, by side; none on
    // any other bar style.
    readonly property var liveElements: appearance.liveElements || { left: [], right: [] }
    // On a capsule, its pill row past its row: the workspace pills with the
    // live elements beside them (CapsulePlacement.pillRow), which stays as it
    // is while a change replaces the row; null on any other bar style.
    readonly property var pillRow: BarProfileModel.capsule(appearance)
        ? CapsulePlacement.pillRow(layoutBar, {
            centre: (rowSpan.start + rowSpan.end) / 2,
            spacing: appearance.spacing,
            pills: workspacePillsLength,
            left: liveElements.left.map(liveEntry),
            right: liveElements.right.map(liveEntry)
        })
        : null
    // How much deeper the live elements make the pill row than the pills
    // alone.
    readonly property real pillRowExtra: pillRow ? pillRow.depth - BarPlacement.workspacePillDepth : 0
    // How deep the deepest live element active on the capsule is, 0 with
    // none: what the capsule reserves for them (BarPlacement.reservedSpace),
    // the same collapsed or expanded, so expanding never moves windows.
    readonly property real activeLiveDepth: Math.max(0, ...liveElements.left.concat(liveElements.right)
        .filter(element => barElementItems.liveActive(element) && elementItem(element) !== null)
        .map(element => elementItem(element).height))
    // On a capsule, where the capsule is drawn around its row and its pill
    // row past it; null on any other bar style.
    readonly property var capsulePlace: pillRow
        ? CapsulePlacement.surface(layoutBar, CapsulePlacement.span(rowSpan, pillRow),
            appearance.horizontalPadding, pillRow.depth + appearance.spacing)
        : null
    // Where a change the capsule shows starts along the bar: centred, as its
    // row would be.
    readonly property real changeStart: BarLayout.zoneStart(layoutBar, "center", changeView.width)
    // Where that change goes in the bar content, { x, y }.
    readonly property var changePlace: BarLayout.place(layoutBar, changeStart, changeView)
    // The open popup when it is inside this bar's capsule, or null.
    readonly property var insidePopup: capsulePlace !== null && openPopup && openPopup.inside
        ? openPopup : null
    // The capsule as drawn: its row, grown round a popup inside it
    // (CapsulePlacement.withPopup); null on any other bar style.
    readonly property var capsuleShape: capsulePlace === null ? null
        : CapsulePlacement.withPopup(capsulePlace, insidePopup, appearance.barPosition)
    // Whether the pointer is over the capsule itself, its workspace pills
    // included, not elsewhere in its bar window.
    readonly property bool capsuleHovered: capsulePlace !== null && pointer.hovered
        && CapsulePlacement.contains(capsulePlace, pointer.point.position)

    HoverHandler {
        id: pointer
    }

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

    // A live element fading out is still visible but no longer shown.
    function elementShown(element) {
        const item = elementItem(element);
        return item !== null && (item.shown !== undefined ? item.shown : item.visible)
            && BarLayout.itemLength(layoutBar, item) > 0;
    }

    // A live element as CapsulePlacement.pillRow takes it.
    function liveEntry(element) {
        const item = elementItem(element);
        return {
            id: element,
            length: item ? BarLayout.itemLength(layoutBar, item) : 0,
            depth: item ? item.height : 0,
            shown: elementShown(element)
        };
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
    // across it; a live element at its place in the pill row.
    function elementPlace(element) {
        if (pillRow && pillRow.elements[element])
            return pillRow.elements[element];

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
    // shown, so the popup opens at an end of the bar.
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
    // isn't shown hangs from the zone at its end of the bar.
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

        spanStart: 0
        spanEnd: root.zoneEnd("left") + leftSurface.endWidth
        popup: root.zonePopup("left")
        motion: root.appearance.motion
        barPosition: root.appearance.barPosition
        thickness: root.sideBar ? root.width : root.height
        visible: BarProfileModel.docked(root.appearance)
        fillColor: root.dockedColor
        border: root.appearance.barBorder
        keepStart: true
        z: -1
    }

    DockedSurface {
        id: centerSurface

        spanStart: root.zoneStart("center") - centerSurface.endWidth
        spanEnd: root.zoneEnd("center") + centerSurface.endWidth
        popup: root.zonePopup("center")
        motion: root.appearance.motion
        barPosition: root.appearance.barPosition
        thickness: root.sideBar ? root.width : root.height
        visible: BarProfileModel.docked(root.appearance)
        fillColor: root.dockedColor
        border: root.appearance.barBorder
        z: -1
    }

    DockedSurface {
        id: rightSurface

        spanStart: root.zoneStart("right") - rightSurface.endWidth
        spanEnd: BarLayout.barLength(root.layoutBar)
        popup: root.zonePopup("right")
        motion: root.appearance.motion
        barPosition: root.appearance.barPosition
        thickness: root.sideBar ? root.width : root.height
        visible: BarProfileModel.docked(root.appearance)
        fillColor: root.dockedColor
        border: root.appearance.barBorder
        keepEnd: true
        z: -1
    }

    CapsuleSurface {
        id: capsuleSurface

        place: root.capsuleShape || { x: 0, y: 0, width: 0, height: 0, radius: 0 }
        following: root.insidePopup !== null && root.insidePopup.resizing
        visible: root.capsulePlace !== null
        fillColor: root.dockedColor
        border: root.appearance.barBorder
        borderColor: theme.border
        appearance: root.appearance
        z: -1
    }

    // Keeps the row and the live elements inside the capsule while the
    // capsule grows or shrinks: bar elements that join an expanding row
    // appear at once where they end up, so they are cut to the capsule as
    // drawn, mid-animation, instead of spilling past it. On any other bar
    // style it cuts nothing.
    Item {
        id: rowClip

        readonly property bool cutting: root.capsulePlace !== null

        x: cutting ? capsuleSurface.x : 0
        y: cutting ? capsuleSurface.y : 0
        width: cutting ? capsuleSurface.width : root.width
        height: cutting ? capsuleSurface.height : root.height
        clip: cutting

        // As large as the bar content and where it is, so what is inside
        // keeps its places.
        Item {
            x: -rowClip.x
            y: -rowClip.y
            width: root.width
            height: root.height

            // A change the capsule shows instead of its row.
            CapsuleChangeView {
                id: changeView

                x: root.changePlace.x
                y: root.changePlace.y
                change: root.capsuleChange
                appearance: root.appearance
                theme: theme
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
                            border.width: root.appearance.groupBorder ? 1 : 0
                            border.color: root.appearance.groupBorder ? theme.border : "transparent"

                            AlongBarBehavior on x { appearance: root.appearance }
                            AlongBarBehavior on y { appearance: root.appearance }
                            AlongBarBehavior on width { appearance: root.appearance }
                            AlongBarBehavior on height { appearance: root.appearance }
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
                AlongBarBehavior on x { appearance: root.appearance; duration: root.appearance.motion.long }
                AlongBarBehavior on y { appearance: root.appearance; duration: root.appearance.motion.long }
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
                AlongBarBehavior on x { appearance: root.appearance; duration: root.appearance.motion.long }
                AlongBarBehavior on y { appearance: root.appearance; duration: root.appearance.motion.long }
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
        }
    }

    BarPopupCloser {
        elementItems: root.elementItems
        onCloseRequested: root.popupCloseRequested()
    }
}
