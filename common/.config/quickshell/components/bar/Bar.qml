import Quickshell
import Quickshell.Wayland
import QtQuick
import "../../config" as Config
import "../panels" as Panels
import "BarPlacement.js" as BarPlacement
import "CapsuleElements.js" as CapsuleElements
import "CapsuleGlance.js" as CapsuleGlance
import "CapsuleMotion.js" as CapsuleMotion
import "LiveElements.js" as LiveElements
import "CapsulePlacement.js" as CapsulePlacement
import "CapsuleRouting.js" as CapsuleRouting
import "../../config/BarProfileModel.js" as BarProfileModel

Variants {
    id: bar

    required property var appearance
    property bool configOpen: false
    property string activePopup: ""
    property var activePopupWindow: null
    required property var monitors
    required property var pomodoro
    required property var notificationHistory
    required property var screenCapture
    // The control center module, handed to its popup.
    required property var controlCenter
    required property var keepAwake
    required property var appMenu
    required property var screenShares
    required property var deviceCaptures
    required property var cava
    required property var systemMonitor
    required property var workspaceService
    required property var monitorSetups
    // The features that open inside a capsule (BarPopups.capsuleFeatures).
    required property var capsuleFeatures

    signal configRequested(var screen, var panelWindow)
    signal panelReady(var screen, var panelWindow)
    signal popupRequested(string popup, var panelWindow)
    signal popupClosed(string popup, var panelWindow)
    signal popupCloseRequested(string element)
    signal audioOutputSelected(var output)
    // A capsule hands back the notifications it can't show any more, to show
    // as toasts (CapsuleNotifications.released).
    signal notificationsReleased(var notifications)

    model: Quickshell.screens

    delegate: Component {
        PanelWindow {
            id: panel

            required property var modelData
            readonly property string monitorDescription: bar.workspaceService.monitorDescriptionForScreen(modelData)
            readonly property string profileName: bar.monitors.barProfileFor(monitorDescription)
            property var barAppearance: QtObject {
                property string barStyle: bar.appearance.barProfileValue(panel.profileName, "barStyle")
                property string barPosition: bar.appearance.barProfileValue(panel.profileName, "barPosition")
                property int barHeight: bar.appearance.barProfileValue(panel.profileName, "barHeight")
                property int horizontalPadding: bar.appearance.barProfileValue(panel.profileName, "horizontalPadding")
                property int spacing: bar.appearance.barProfileValue(panel.profileName, "spacing")
                property int radius: bar.appearance.barProfileValue(panel.profileName, "radius")
                property int workspaceButtonSize: bar.appearance.barProfileValue(panel.profileName, "workspaceButtonSize")
                property int textSize: bar.appearance.barProfileValue(panel.profileName, "textSize")
                property int iconSize: bar.appearance.barProfileValue(panel.profileName, "iconSize")
                property int archButtonHorizontalPadding: bar.appearance.barProfileValue(panel.profileName, "archButtonHorizontalPadding")
                property int activeWorkspaceHorizontalPadding: bar.appearance.barProfileValue(panel.profileName, "activeWorkspaceHorizontalPadding")
                property int pillVerticalPadding: bar.appearance.barProfileValue(panel.profileName, "pillVerticalPadding")
                property int elementVerticalPadding: bar.appearance.barProfileValue(panel.profileName, "elementVerticalPadding")
                property bool pillsTransparent: bar.appearance.barProfileValue(panel.profileName, "pillsTransparent")
                property int transparentBarTopMargin: bar.appearance.barProfileValue(panel.profileName, "transparentBarTopMargin")
                property int groupRadius: bar.appearance.barProfileValue(panel.profileName, "groupRadius")
                property int groupHorizontalPadding: bar.appearance.barProfileValue(panel.profileName, "groupHorizontalPadding")
                property int groupVerticalPadding: bar.appearance.barProfileValue(panel.profileName, "groupVerticalPadding")
                property int capsuleVerticalPadding: bar.appearance.barProfileValue(panel.profileName, "capsuleVerticalPadding")
                property bool barBorder: bar.appearance.barProfileValue(panel.profileName, "barBorder")
                property bool elementBorder: bar.appearance.barProfileValue(panel.profileName, "elementBorder")
                property bool groupBorder: bar.appearance.barProfileValue(panel.profileName, "groupBorder")
                property int barOpacity: bar.appearance.barProfileValue(panel.profileName, "barOpacity")
                property bool capsuleNotifications: bar.appearance.barProfileValue(panel.profileName, "capsuleNotifications")
                // On a capsule, only the row it shows (see CapsuleElements.drawnElements):
                // the view its crossfade shows (rowView), the new one from
                // the frame after a change; a capture of the old one fades out.
                // Expanded, the elements whose glance cards show leave it.
                property var barElements: CapsuleElements.drawnElements({
                    barStyle: panel.barAppearance.barStyle,
                    barElements: bar.appearance.barProfileValue(panel.profileName, "barElements"),
                    expanded: rowView.shownKey === "expanded",
                    change: rowView.shownKey === "change",
                    glance: glanceElements,
                    capsulePlaces: bar.appearance.barProfileValue(panel.profileName, "capsulePlaces")
                })
                // On a capsule, the live elements beside its workspace pills,
                // by side (see LiveElements.liveElements); none otherwise.
                property var liveElements: LiveElements.liveElements({
                    barStyle: panel.barAppearance.barStyle,
                    barElements: bar.appearance.barProfileValue(panel.profileName, "barElements"),
                    capsulePlaces: bar.appearance.barProfileValue(panel.profileName, "capsulePlaces")
                })
                // The bar elements whose glance cards show
                // (CapsuleGlance.leavingElements): they leave the expanded
                // row and, live, their place beside the pills.
                property var glanceElements: CapsuleGlance.leavingElements(barContent.glanceCards,
                    panel.glanceShown)
                // Whether this window's capsule is expanded (see panel.capsuleExpanded).
                property bool capsuleExpanded: panel.capsuleExpanded
                // Whether its row shows its expanded view (the crossfade's
                // "expanded"), when the capsule looks expanded
                // (CapsuleLook.looksExpanded): not with a popup inside, its
                // row at rest, nor while a change shows instead.
                property bool capsuleRowExpanded: rowView.shownKey === "expanded"
                // Global, not part of the bar profile.
                property bool doNotDisturb: bar.appearance.doNotDisturb
                property var controlCenterTiles: bar.appearance.controlCenterTiles
                property var motion: bar.appearance.motion
            }
            // Whether this window's capsule is expanded, held by any of its
            // causes (see CapsuleRouting.expanded); always false on other bar styles,
            // where nothing reads it. Its size changes as the row does,
            // animated, and the reserved space stays as it is collapsed.
            // A popup inside doesn't hold it: like a dynamic island, the
            // capsule then fits the popup and the row at rest, and hovering
            // the row still expands it to switch popups.
            readonly property bool capsuleExpanded: CapsuleRouting.expanded({
                hover: capsuleHover.expanded,
                toggled: capsuleToggle.toggled
            })
            // Whether this window's capsule shows a change instead of its row:
            // for a moment after one (see CapsuleChange.qml), unless a popup
            // is inside, which a change never interrupts.
            readonly property bool showingChange: capsuleChange.showing && panel.activePopup === ""
            // Whether this window's capsule shows its glance under its
            // expanded row (CapsuleGlance.shown): expanded by hovering or
            // SUPER+I, as the row shows it, not for a change nor with a popup
            // inside, and with cards to show. Always false on other bar
            // styles, whose row view is always "rest".
            readonly property bool glanceShown: CapsuleGlance.shown({
                view: rowView.shownKey,
                popupInside: panel.activePopup !== "",
                cards: barContent.glanceCards
            })
            // Whether this window's capsule is hidden, while its monitor's
            // focused workspace has a real fullscreen window (see
            // CapsuleRouting.hidden); always false on other bar styles. It
            // fades out, takes no clicks and keeps its reserved space;
            // modules/Bar.qml lists it so changes go to the OSD instead.
            readonly property bool capsuleHidden: CapsuleRouting.hidden({
                capsule: BarProfileModel.capsule(panel.barAppearance),
                fullscreen: bar.workspaceService.hasFullscreenOn(panel.modelData)
            })
            // Whether this window's capsule can show new notifications (see
            // CapsuleRouting.holdsNotifications, which
            // CapsuleRouting.notificationTarget asks too). Once it can't,
            // those it holds show as toasts.
            readonly property bool holdsNotifications: CapsuleRouting.holdsNotifications({
                visible: panel.visible,
                capsule: BarProfileModel.capsule(panel.barAppearance),
                capsuleHidden: panel.capsuleHidden,
                popupInside: panel.activePopup !== "",
                capsuleNotifications: panel.barAppearance.capsuleNotifications
            })
            onHoldsNotificationsChanged: {
                if (!panel.holdsNotifications)
                    capsuleNotifications.release();
            }
            // A popup inside the capsule closes with it.
            onCapsuleHiddenChanged: {
                if (panel.capsuleHidden && panel.activePopup !== "")
                    bar.popupClosed(panel.activePopup, panel);
            }
            property bool configOpen: bar.configOpen
            property string activePopup: bar.activePopupWindow === panel
                ? bar.activePopup : ""
            property var monitors: bar.monitors
            property var pomodoro: bar.pomodoro
            property var notificationHistory: bar.notificationHistory
            property var screenCapture: bar.screenCapture
            property var keepAwake: bar.keepAwake
            property var appMenu: bar.appMenu
            property var screenShares: bar.screenShares
            property var deviceCaptures: bar.deviceCaptures
            property var cava: bar.cava
            property var systemMonitor: bar.systemMonitor
            property var workspaceService: bar.workspaceService

            Component.onCompleted: bar.panelReady(panel.screen, panel)

            screen: modelData
            // A monitor mirroring another stays a screen, showing the other's bar already.
            visible: bar.monitors.barVisible(
                monitorDescription
            ) && !bar.monitorSetups.isMirroring(modelData.name)
            WlrLayershell.namespace: "ndro-shell-bar"
            WlrLayershell.layer: WlrLayer.Top
            color: "transparent"
            // The whole window takes clicks, except on a capsule: only the
            // capsule does, a popup inside included, so clicks beside it reach
            // the windows below; none while it is hidden for fullscreen.
            readonly property var inputRegion: panel.capsuleHidden
                ? { x: 0, y: 0, width: 0, height: 0 }
                : barContent.capsuleShape
                ? CapsulePlacement.inputRegion(barContent.capsuleShape, { left: barContent.x, top: barContent.y })
                : { x: 0, y: 0, width: panel.width, height: panel.height }
            mask: Region {
                x: panel.inputRegion.x
                y: panel.inputRegion.y
                width: panel.inputRegion.width
                height: panel.inputRegion.height
            }
            readonly property int barThickness: BarPlacement.thickness(panel.barAppearance)
            readonly property var windowAnchors: BarPlacement.windowAnchors(panel.barAppearance.barPosition)
            // Where the bar content sits: against the screen edge, as deep as
            // the bar, so it keeps its place and depth in a capsule's window
            // grown for a popup inside (BarPlacement.contentArea).
            readonly property var contentArea: BarPlacement.contentArea(panel.barAppearance,
                { width: barBackground.width, height: barBackground.height })

            // On a capsule, the live elements it shows collapsed included,
            // so windows move clear of them as they appear and back as they go.
            exclusiveZone: BarPlacement.reservedSpace(panel.barAppearance, barContent.activeLiveDepth)
            // Only the size across the bar counts: the compositor stretches the
            // window between the two anchors it has along the bar. A capsule's
            // window grows away from its edge to hold a popup inside, and a
            // pill row deepened by its live elements.
            implicitWidth: barThickness
            implicitHeight: barThickness
                + (BarProfileModel.capsule(panel.barAppearance)
                    ? capsuleWindowHold.held + barContent.pillRowExtra : 0)

            anchors {
                top: panel.windowAnchors.top
                bottom: panel.windowAnchors.bottom
                left: panel.windowAnchors.left
                right: panel.windowAnchors.right
            }

            Config.Theme {
                id: theme
            }

            // Hovering the capsule expands it after a moment; not over a live
            // element, whose click opens its popup straight from rest.
            CapsuleHover {
                id: capsuleHover

                hovering: barContent.capsuleHoverExpands
            }

            // How much taller a capsule's window is for the popups and the
            // glance inside it.
            CapsuleWindowHold {
                id: capsuleWindowHold

                needed: Math.max(barPopups.openPopup && barPopups.openPopup.inside
                    ? barPopups.openPopup.windowHeight : 0,
                    barContent.glanceSize ? barContent.glanceSize.height : 0)
            }

            // SUPER+I expands the capsule until pressed again or until the
            // pointer leaves it.
            CapsuleToggle {
                id: capsuleToggle

                hovering: barContent.capsuleHovered
            }

            // The capsule's row crossfades between its views, at rest,
            // expanded or showing a change (CapsuleRouting.rowView): the new
            // row is drawn a frame after the change, which springs the
            // capsule to fit it at once; a capture of the old row fades and
            // shrinks away as it moves (BarContent's rowOutgoing) and the new
            // one fades and grows in from a third of the way. Expanding, the
            // new row's bar elements instead enter one after another from its
            // centre out (BarContent's rowEntering), and the crossfade runs
            // until the last is in. Always "rest" on other bar styles, which
            // never crossfade.
            CapsuleContentTransition {
                id: rowView

                // Whether the expanded row is entering.
                readonly property bool entering: changing && shownKey === "expanded"

                key: BarProfileModel.capsule(panel.barAppearance) ? CapsuleRouting.rowView({
                    change: panel.showingChange,
                    expanded: panel.capsuleExpanded
                }) : "rest"
                motion: panel.barAppearance.motion
                length: shownKey === "expanded"
                    ? CapsuleMotion.entryLength(motion, barContent.rowEntry.steps
                        + (panel.glanceShown ? barContent.glanceCards.length : 0)) : 0
                visible: false
            }

            // A change (volume, brightness, Caps Lock, audio output, bar
            // profile or keep-awake) shows in the capsule for a moment.
            CapsuleChange {
                id: capsuleChange
            }

            // Shows a change in this window's capsule instead of the OSD;
            // modules/Osd.qml calls it on the focused monitor's (see
            // CapsuleRouting.changeTarget).
            function showChange(change) {
                capsuleChange.show(change);
            }

            // The notifications this window's capsule shows; Do Not Disturb
            // drops them, as it hides toasts.
            CapsuleNotifications {
                id: capsuleNotifications

                onReleased: notifications => bar.notificationsReleased(notifications)
            }

            Connections {
                target: bar.appearance

                function onDoNotDisturbChanged() {
                    if (bar.appearance.doNotDisturb)
                        capsuleNotifications.clear();
                }
            }

            // Shows a new notification in this window's capsule instead of as
            // a toast; modules/Notifications.qml calls it on the focused
            // monitor's (see CapsuleRouting.notificationTarget).
            function showNotification(notification) {
                capsuleNotifications.show(notification);
            }

            // Expands this window's capsule, or collapses it if SUPER+I
            // expanded it; modules/Bar.qml calls it on the focused monitor's.
            function toggleCapsule() {
                capsuleToggle.toggle();
            }

            Rectangle {
                id: barBackground

                anchors.fill: parent
                opacity: panel.capsuleHidden ? 0 : 1
                color: !BarProfileModel.opaque(panel.barAppearance)
                    ? "transparent" : Qt.rgba(theme.background.r, theme.background.g,
                        theme.background.b, panel.barAppearance.barOpacity / 100)

                Behavior on color {
                    ColorAnimation {
                        duration: panel.barAppearance.motion.long
                        easing.type: panel.barAppearance.motion.easing
                    }
                }

                Behavior on opacity {
                    NumberAnimation {
                        duration: panel.barAppearance.motion.short
                        easing.type: panel.barAppearance.motion.easing
                    }
                }

                // An opaque bar's bar border, along its edge facing the desktop.
                Repeater {
                    model: panel.barAppearance.barBorder && BarProfileModel.opaque(panel.barAppearance)
                        ? BarPlacement.edgeBorder(panel.barAppearance.barPosition,
                            { width: barBackground.width, height: barBackground.height },
                            barPopups.openPopup
                                ? { start: barPopups.openPopup.start, end: barPopups.openPopup.end } : null)
                        : []

                    delegate: Rectangle {
                        required property var modelData

                        x: modelData.x
                        y: modelData.y
                        width: modelData.width
                        height: modelData.height
                        color: theme.border
                        z: 1
                    }
                }

                BarContent {
                    id: barContent

                    x: panel.contentArea.x
                    y: panel.contentArea.y
                    width: panel.contentArea.width
                    height: panel.contentArea.height
                    appearance: panel.barAppearance
                    configOpen: panel.configOpen
                    activePopup: panel.activePopup
                    openPopup: barPopups.openPopup
                    monitorScreen: panel.screen
                    monitors: panel.monitors
                    pomodoro: panel.pomodoro
                    notificationHistory: panel.notificationHistory
                    screenCapture: panel.screenCapture
                    keepAwake: panel.keepAwake
                    appMenu: panel.appMenu
                    screenShares: panel.screenShares
                    deviceCaptures: panel.deviceCaptures
                    cava: panel.cava
                    barVisible: panel.visible
                    systemMonitor: panel.systemMonitor
                    workspaceService: panel.workspaceService
                    capsuleChange: rowView.shownKey === "change" ? capsuleChange.change : null
                    rowContents: ({ opacity: rowView.contentsOpacity, scale: rowView.contentsScale })
                    rowEntering: rowView.entering
                    rowElapsed: rowView.elapsed
                    rowOutgoing: ({ capturing: rowView.capturing, opacity: rowView.outgoingOpacity,
                        scale: rowView.outgoingScale })
                    workspacePillsLength: workspaceRow.length
                    workspacePillsDepth: workspaceRow.depth
                    glanceShown: panel.glanceShown

                    onConfigRequested: function(screen) {
                        bar.configRequested(screen, panel);
                    }

                    onPopupRequested: function(popup) {
                        bar.popupRequested(popup, panel);
                    }

                    onPopupCloseRequested: element => bar.popupCloseRequested(element)
                }
            }

            // A capsule's workspace pills, inside the capsule past its row,
            // beside its live elements (CapsulePlacement.pillRow), so they
            // take clicks with it. They slide to make room for a live element.
            CapsuleWorkspaceRow {
                id: workspaceRow

                readonly property var place: barContent.pillRow ? barContent.pillRow.pills : null

                // The pill row can arrive a moment before the capsule's place.
                visible: place !== null && barContent.capsulePlace !== null
                    && barContent.capsulePlace.width > 0
                opacity: barBackground.opacity
                x: place ? barContent.x + place.x : 0
                y: place ? barContent.y + place.y : 0
                workspaceIds: panel.workspaceService.workspacesForScreen(panel.screen,
                    panel.monitors.workspacesFor(panel.monitorDescription))
                workspaceService: panel.workspaceService
                monitorScreen: panel.screen
                appearance: panel.barAppearance
                // Chips while its row shows expanded, as its bar elements do.
                expanded: rowView.shownKey === "expanded"
                workspaceOptions: BarProfileModel.elementOptions(
                    bar.appearance.barProfileValue(panel.profileName, "barElements"), "workspaces")

                AlongBarBehavior on x { appearance: panel.barAppearance }
            }

            Panels.BarPopups {
                id: barPopups

                appearance: panel.barAppearance
                barWindow: panel
                popupAnchorProvider: barContent
                appMenuId: barContent.appMenuId
                activePopup: panel.activePopup
                pomodoro: panel.pomodoro
                keepAwake: panel.keepAwake
                deviceCaptures: panel.deviceCaptures
                appMenu: panel.appMenu
                systemMonitor: panel.systemMonitor
                controlCenter: bar.controlCenter
                capsuleFeatures: bar.capsuleFeatures
                capsuleNotifications: capsuleNotifications

                onPopupClosed: function(popup) {
                    bar.popupClosed(popup, panel);
                }

                onAudioOutputSelected: function(output) {
                    bar.audioOutputSelected(output);
                }
            }

        }
    }
}
