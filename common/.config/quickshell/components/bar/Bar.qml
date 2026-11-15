import Quickshell
import Quickshell.Wayland
import QtQuick
import "../../config" as Config
import "../panels" as Panels
import "BarPlacement.js" as BarPlacement
import "Capsule.js" as Capsule

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
    required property var cava
    required property var systemMonitor
    required property var workspaceService
    required property var monitorSetups

    signal configRequested(var screen, var panelWindow)
    signal panelReady(var screen, var panelWindow)
    signal popupRequested(string popup, var panelWindow)
    signal popupClosed(string popup, var panelWindow)
    signal popupCloseRequested()
    signal audioOutputSelected(var output)

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
                property int workspacePadding: bar.appearance.barProfileValue(panel.profileName, "workspacePadding")
                property int elementVerticalPadding: bar.appearance.barProfileValue(panel.profileName, "elementVerticalPadding")
                property bool pillsTransparent: bar.appearance.barProfileValue(panel.profileName, "pillsTransparent")
                property int transparentBarTopMargin: bar.appearance.barProfileValue(panel.profileName, "transparentBarTopMargin")
                property int groupRadius: bar.appearance.barProfileValue(panel.profileName, "groupRadius")
                property int groupHorizontalPadding: bar.appearance.barProfileValue(panel.profileName, "groupHorizontalPadding")
                property int groupVerticalPadding: bar.appearance.barProfileValue(panel.profileName, "groupVerticalPadding")
                property bool barBorder: bar.appearance.barProfileValue(panel.profileName, "barBorder")
                property bool elementBorder: bar.appearance.barProfileValue(panel.profileName, "elementBorder")
                property bool groupBorder: bar.appearance.barProfileValue(panel.profileName, "groupBorder")
                property int barOpacity: bar.appearance.barProfileValue(panel.profileName, "barOpacity")
                // On a capsule, only the row it shows (see Capsule.drawnElements).
                property var barElements: Capsule.drawnElements({
                    barStyle: bar.appearance.barProfileValue(panel.profileName, "barStyle"),
                    barElements: bar.appearance.barProfileValue(panel.profileName, "barElements"),
                    expanded: panel.capsuleExpanded,
                    capsuleElements: bar.appearance.barProfileValue(panel.profileName, "capsuleElements")
                })
                // Whether this window's capsule is expanded (see panel.capsuleExpanded).
                property bool capsuleExpanded: panel.capsuleExpanded
                // Global, not part of the bar profile.
                property bool doNotDisturb: bar.appearance.doNotDisturb
                property var controlCenterTiles: bar.appearance.controlCenterTiles
                property var motion: bar.appearance.motion
            }
            // Whether this window's capsule is expanded, held by any of its
            // causes (see Capsule.expanded); always false on other bar styles,
            // where nothing reads it. Its size changes as the row does,
            // animated, and the reserved space stays at the collapsed height.
            // A popup inside holds it expanded until the popup closes.
            readonly property bool capsuleExpanded: Capsule.expanded({
                hover: capsuleHover.expanded,
                toggled: capsuleToggle.toggled,
                popupInside: panel.activePopup !== ""
            })
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
            // the windows below.
            readonly property var inputRegion: barContent.capsuleShape
                ? Capsule.inputRegion(barContent.capsuleShape, { left: barContent.x, top: barContent.y })
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

            exclusiveZone: barThickness
            // Only the size across the bar counts: the compositor stretches the
            // window between the two anchors it has along the bar. A capsule's
            // window grows away from its edge to hold a popup inside, past
            // what it reserves.
            implicitWidth: barThickness
            implicitHeight: barThickness
                + (panel.barAppearance.barStyle === "capsule" ? capsuleWindowHold.held : 0)

            anchors {
                top: panel.windowAnchors.top
                bottom: panel.windowAnchors.bottom
                left: panel.windowAnchors.left
                right: panel.windowAnchors.right
            }

            Config.Theme {
                id: theme
            }

            // Hovering the capsule expands it after a moment.
            CapsuleHover {
                id: capsuleHover

                hovering: barContent.capsuleHovered
            }

            // How much taller a capsule's window is for the popups inside it.
            CapsuleWindowHold {
                id: capsuleWindowHold

                needed: barPopups.openPopup && barPopups.openPopup.inside
                    ? barPopups.openPopup.windowHeight : 0
            }

            // SUPER+I expands the capsule until pressed again or until the
            // pointer leaves it.
            CapsuleToggle {
                id: capsuleToggle

                hovering: barContent.capsuleHovered
            }

            // Expands this window's capsule, or collapses it if SUPER+I
            // expanded it; modules/Bar.qml calls it on the focused monitor's.
            function toggleCapsule() {
                capsuleToggle.toggle();
            }

            Rectangle {
                id: barBackground

                anchors.fill: parent
                color: panel.barAppearance.barStyle !== "opaque"
                    ? "transparent" : Qt.rgba(theme.background.r, theme.background.g,
                        theme.background.b, panel.barAppearance.barOpacity / 100)

                Behavior on color {
                    ColorAnimation {
                        duration: panel.barAppearance.motion.long
                        easing.type: panel.barAppearance.motion.easing
                    }
                }

                // An opaque bar's bar border, along its edge facing the desktop.
                Repeater {
                    model: panel.barAppearance.barBorder && panel.barAppearance.barStyle === "opaque"
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
                    cava: panel.cava
                    barVisible: panel.visible
                    systemMonitor: panel.systemMonitor
                    workspaceService: panel.workspaceService

                    onConfigRequested: function(screen) {
                        bar.configRequested(screen, panel);
                    }

                    onPopupRequested: function(popup) {
                        bar.popupRequested(popup, panel);
                    }

                    onPopupCloseRequested: bar.popupCloseRequested()
                }
            }

            // A capsule's workspace row, in a window of its own past what the
            // capsule reserves, so the bar window keeps the capsule's size and
            // only the capsule's height is reserved.
            PanelWindow {
                id: workspaceRowWindow

                readonly property var place: Capsule.workspaceRow(panel.barAppearance,
                    panel.inputRegion)

                screen: panel.screen
                // Hidden while a popup is inside the capsule.
                visible: panel.visible && place !== null && panel.activePopup === ""
                WlrLayershell.namespace: "ndro-shell-capsule-workspaces"
                WlrLayershell.layer: WlrLayer.Top
                exclusionMode: ExclusionMode.Normal
                exclusiveZone: 0
                color: "transparent"
                implicitHeight: workspaceRow.implicitHeight
                mask: Region {
                    item: workspaceRow
                }

                anchors {
                    top: workspaceRowWindow.place ? workspaceRowWindow.place.anchors.top : true
                    bottom: workspaceRowWindow.place ? workspaceRowWindow.place.anchors.bottom : false
                    left: true
                    right: true
                }
                margins {
                    top: workspaceRowWindow.place ? workspaceRowWindow.place.margin : 0
                    bottom: workspaceRowWindow.place ? workspaceRowWindow.place.margin : 0
                }

                CapsuleWorkspaceRow {
                    id: workspaceRow

                    x: workspaceRowWindow.place
                        ? workspaceRowWindow.place.centre - workspaceRow.width / 2 : 0
                    workspaceIds: panel.workspaceService.workspacesForScreen(panel.screen,
                        panel.monitors.workspacesFor(panel.monitorDescription))
                    workspaceService: panel.workspaceService
                    fillColor: barContent.dockedColor
                    border: panel.barAppearance.barBorder
                    borderColor: theme.border
                    appearance: panel.barAppearance

                    AlongBarBehavior on x { appearance: panel.barAppearance }
                }
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
                appMenu: panel.appMenu
                systemMonitor: panel.systemMonitor
                controlCenter: bar.controlCenter

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
