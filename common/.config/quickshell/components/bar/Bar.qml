import Quickshell
import Quickshell.Wayland
import QtQuick
import "../../config" as Config
import "../panels" as Panels
import "BarPlacement.js" as BarPlacement

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
                property string barPosition: bar.appearance.barProfileValue(panel.profileName, "barPosition")
                property int barHeight: bar.appearance.barProfileValue(panel.profileName, "barHeight")
                property int horizontalPadding: bar.appearance.barProfileValue(panel.profileName, "horizontalPadding")
                property int spacing: bar.appearance.barProfileValue(panel.profileName, "spacing")
                property int radius: bar.appearance.barProfileValue(panel.profileName, "radius")
                property int workspaceButtonSize: bar.appearance.barProfileValue(panel.profileName, "workspaceButtonSize")
                property int textSize: bar.appearance.barProfileValue(panel.profileName, "textSize")
                property int archButtonHorizontalPadding: bar.appearance.barProfileValue(panel.profileName, "archButtonHorizontalPadding")
                property int activeWorkspaceHorizontalPadding: bar.appearance.barProfileValue(panel.profileName, "activeWorkspaceHorizontalPadding")
                property int pillVerticalPadding: bar.appearance.barProfileValue(panel.profileName, "pillVerticalPadding")
                property int workspacePadding: bar.appearance.barProfileValue(panel.profileName, "workspacePadding")
                property int elementVerticalPadding: bar.appearance.barProfileValue(panel.profileName, "elementVerticalPadding")
                property bool pillsTransparent: bar.appearance.barProfileValue(panel.profileName, "pillsTransparent")
                property int transparentBarTopMargin: bar.appearance.barProfileValue(panel.profileName, "transparentBarTopMargin")
                property bool transparentBarSlanted: bar.appearance.barProfileValue(panel.profileName, "transparentBarSlanted")
                property int groupRadius: bar.appearance.barProfileValue(panel.profileName, "groupRadius")
                property bool barTransparent: bar.appearance.barProfileValue(panel.profileName, "barTransparent")
                property bool barBorder: bar.appearance.barProfileValue(panel.profileName, "barBorder")
                property bool elementBorder: bar.appearance.barProfileValue(panel.profileName, "elementBorder")
                property bool groupBorder: bar.appearance.barProfileValue(panel.profileName, "groupBorder")
                property int barOpacity: bar.appearance.barProfileValue(panel.profileName, "barOpacity")
                property var barElements: bar.appearance.barProfileValue(panel.profileName, "barElements")
                // Global, not part of the bar profile.
                property bool doNotDisturb: bar.appearance.doNotDisturb
                property var controlCenterTiles: bar.appearance.controlCenterTiles
                property var motion: bar.appearance.motion
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
            mask: Region {
                x: 0
                y: 0
                width: panel.width
                height: panel.height
            }
            readonly property int barThickness: BarPlacement.thickness(panel.barAppearance)
            readonly property var windowAnchors: BarPlacement.windowAnchors(panel.barAppearance.barPosition)
            readonly property var contentMargins: BarPlacement.contentMargins(panel.barAppearance)

            exclusiveZone: barThickness
            // Only the size across the bar counts: the compositor stretches the
            // window between the two anchors it has along the bar.
            implicitWidth: barThickness
            implicitHeight: barThickness

            anchors {
                top: panel.windowAnchors.top
                bottom: panel.windowAnchors.bottom
                left: panel.windowAnchors.left
                right: panel.windowAnchors.right
            }

            Config.Theme {
                id: theme
            }

            Rectangle {
                id: barBackground

                anchors.fill: parent
                color: panel.barAppearance.barTransparent
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
                    model: panel.barAppearance.barBorder && !panel.barAppearance.barTransparent
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

                    anchors.fill: parent
                    anchors.leftMargin: panel.contentMargins.left
                    anchors.rightMargin: panel.contentMargins.right
                    anchors.topMargin: panel.contentMargins.top
                    anchors.bottomMargin: panel.contentMargins.bottom
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
