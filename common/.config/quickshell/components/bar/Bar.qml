import Quickshell
import Quickshell.Wayland
import QtQuick
import "../../config" as Config
import "../panels" as Panels

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
    required property var screenShares
    required property var cava
    required property var systemMonitor
    required property var workspaceService

    signal configRequested(var screen, var panelWindow)
    signal panelReady(var screen, var panelWindow)
    signal popupRequested(string popup, var panelWindow)
    signal popupClosed(string popup, var panelWindow)
    signal audioOutputSelected(var output)

    model: Quickshell.screens

    delegate: Component {
        PanelWindow {
            id: panel

            required property var modelData
            readonly property string monitorDescription: bar.workspaceService.monitorDescriptionForScreen(modelData)
            readonly property string profileName: bar.monitors.barProfileFor(monitorDescription)
            property var barAppearance: QtObject {
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
                property bool barTransparentBorder: bar.appearance.barProfileValue(panel.profileName, "barTransparentBorder")
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
            property var screenShares: bar.screenShares
            property var cava: bar.cava
            property var systemMonitor: bar.systemMonitor
            property var workspaceService: bar.workspaceService

            Component.onCompleted: bar.panelReady(panel.screen, panel)

            screen: modelData
            visible: bar.monitors.barVisible(
                monitorDescription
            )
            WlrLayershell.namespace: "ndro-shell-bar"
            WlrLayershell.layer: WlrLayer.Top
            color: "transparent"
            mask: Region {
                x: 0
                y: 0
                width: panel.width
                height: panel.height
            }
            readonly property int totalBarHeight: panel.barAppearance.barHeight
                + (panel.barAppearance.barTransparent
                    && !panel.barAppearance.transparentBarSlanted
                    ? panel.barAppearance.transparentBarTopMargin : 0)

            exclusiveZone: totalBarHeight
            implicitHeight: totalBarHeight

            anchors {
                top: true
                left: true
                right: true
            }

            Config.Theme {
                id: theme
            }

            Rectangle {
                id: barBackground

                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                height: panel.totalBarHeight
                color: panel.barAppearance.barTransparent
                    ? "transparent" : Qt.rgba(theme.background.r, theme.background.g,
                        theme.background.b, panel.barAppearance.barOpacity / 100)

                Behavior on color {
                    ColorAnimation {
                        duration: panel.barAppearance.motion.long
                        easing.type: panel.barAppearance.motion.easing
                    }
                }

                BarContent {
                    id: barContent

                    anchors.fill: parent
                    anchors.leftMargin: panel.barAppearance.barTransparent
                        && panel.barAppearance.transparentBarSlanted ? 0 : panel.barAppearance.horizontalPadding
                    anchors.rightMargin: panel.barAppearance.barTransparent
                        && panel.barAppearance.transparentBarSlanted ? 0 : panel.barAppearance.horizontalPadding
                    anchors.topMargin: panel.barAppearance.barTransparent
                        && !panel.barAppearance.transparentBarSlanted
                        ? panel.barAppearance.transparentBarTopMargin : 0
                    appearance: panel.barAppearance
                    configOpen: panel.configOpen
                    activePopup: panel.activePopup
                    monitorScreen: panel.screen
                    monitors: panel.monitors
                    pomodoro: panel.pomodoro
                    notificationHistory: panel.notificationHistory
                    screenCapture: panel.screenCapture
                    keepAwake: panel.keepAwake
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
                }
            }

            Panels.BarPopups {
                appearance: panel.barAppearance
                barWindow: panel
                popupAnchorProvider: barContent
                activePopup: panel.activePopup
                pomodoro: panel.pomodoro
                keepAwake: panel.keepAwake
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
