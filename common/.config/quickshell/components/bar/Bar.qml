import Quickshell
import Quickshell.Wayland
import QtQuick
import "../../config" as Config
import "../panels" as Panels

Variants {
    id: bar

    required property var appearance
    property bool configOpen: false
    property string activeStatusPopup: ""
    property var activeStatusPopupWindow: null
    required property var monitors
    required property var pomodoro
    required property var notificationHistory
    required property var screenCapture
    required property var systemMonitor
    required property var workspaceService

    signal configRequested(var screen, var panelWindow)
    signal panelReady(var screen, var panelWindow)
    signal statusPopupRequested(string popup, var panelWindow)
    signal statusPopupClosed(string popup, var panelWindow)
    signal audioSinkSelected(var sink)
    signal notificationRequested()

    model: Quickshell.screens

    delegate: Component {
        PanelWindow {
            id: panel

            required property var modelData
            readonly property string monitorDescription: bar.workspaceService.monitorDescriptionForScreen(modelData)
            readonly property string profileName: bar.monitors.barProfileFor(
                monitorDescription, bar.appearance.activeBarProfile
            )
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
                property bool workspaceGlyphsEnabled: bar.appearance.barProfileValue(panel.profileName, "workspaceGlyphsEnabled")
                property bool hideEmptyWorkspaces: bar.appearance.barProfileValue(panel.profileName, "hideEmptyWorkspaces")
                property bool workspaceAppCountVisible: bar.appearance.barProfileValue(panel.profileName, "workspaceAppCountVisible")
                property var workspaceGlyphs: bar.appearance.barProfileValue(panel.profileName, "workspaceGlyphs")
                property bool pillsTransparent: bar.appearance.barProfileValue(panel.profileName, "pillsTransparent")
                property int transparentBarTopMargin: bar.appearance.barProfileValue(panel.profileName, "transparentBarTopMargin")
                property bool transparentBarSlanted: bar.appearance.barProfileValue(panel.profileName, "transparentBarSlanted")
                property bool statusIsland: bar.appearance.barProfileValue(panel.profileName, "statusIsland")
                property int statusIslandRadius: bar.appearance.barProfileValue(panel.profileName, "statusIslandRadius")
                property bool barTransparent: bar.appearance.barProfileValue(panel.profileName, "barTransparent")
                property bool barTransparentBorder: bar.appearance.barProfileValue(panel.profileName, "barTransparentBorder")
                property var statusModuleOrder: bar.appearance.barProfileValue(panel.profileName, "statusModuleOrder")
                property var statusModuleEnabled: bar.appearance.barProfileValue(panel.profileName, "statusModuleEnabled")
                property var statusModuleGroups: bar.appearance.barProfileValue(panel.profileName, "statusModuleGroups")
                property var statusModulePlacement: bar.appearance.barProfileValue(panel.profileName, "statusModulePlacement")
                property var barElementEnabled: bar.appearance.barProfileValue(panel.profileName, "barElementEnabled")
                property var barElementPlacement: bar.appearance.barProfileValue(panel.profileName, "barElementPlacement")
            }
            property bool configOpen: bar.configOpen
            property string activeStatusPopup: bar.activeStatusPopupWindow === panel
                ? bar.activeStatusPopup : ""
            property var monitors: bar.monitors
            property var pomodoro: bar.pomodoro
            property var notificationHistory: bar.notificationHistory
            property var screenCapture: bar.screenCapture
            property var systemMonitor: bar.systemMonitor
            property var workspaceService: bar.workspaceService

            Component.onCompleted: bar.panelReady(panel.screen, panel)

            screen: modelData
            visible: bar.monitors.barVisible(
                monitorDescription
            )
            WlrLayershell.namespace: "ndro-shell-bar"
            color: "transparent"
            mask: Region {
                x: 0
                y: 0
                width: panel.width
                height: panel.height
            }
            readonly property int totalBarHeight: panel.barAppearance.barHeight
                + ((panel.barAppearance.barTransparent || panel.barAppearance.statusIsland)
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
                color: panel.barAppearance.barTransparent || panel.barAppearance.statusIsland
                    ? "transparent" : theme.background

                Behavior on color {
                    ColorAnimation {
                        duration: 220
                        easing.type: Easing.OutCubic
                    }
                }

                BarContent {
                    id: barContent

                    anchors.fill: parent
                    anchors.leftMargin: panel.barAppearance.barTransparent
                        && panel.barAppearance.transparentBarSlanted ? 0 : panel.barAppearance.horizontalPadding
                    anchors.rightMargin: panel.barAppearance.barTransparent
                        && panel.barAppearance.transparentBarSlanted ? 0 : panel.barAppearance.horizontalPadding
                    anchors.topMargin: (panel.barAppearance.barTransparent || panel.barAppearance.statusIsland)
                        && !panel.barAppearance.transparentBarSlanted
                        ? panel.barAppearance.transparentBarTopMargin : 0
                    appearance: panel.barAppearance
                    configOpen: panel.configOpen
                    activeStatusPopup: panel.activeStatusPopup
                    monitorScreen: panel.screen
                    monitors: panel.monitors
                    pomodoro: panel.pomodoro
                    notificationHistory: panel.notificationHistory
                    screenCapture: panel.screenCapture
                    systemMonitor: panel.systemMonitor
                    workspaceService: panel.workspaceService

                    onConfigRequested: function(screen) {
                        bar.configRequested(screen, panel);
                    }

                    onStatusPopupRequested: function(popup) {
                        bar.statusPopupRequested(popup, panel);
                    }

                    onNotificationRequested: bar.notificationRequested()
                }
            }

            Panels.StatusPopups {
                appearance: panel.barAppearance
                barWindow: panel
                popupAnchorProvider: barContent
                activePopup: panel.activeStatusPopup
                pomodoro: panel.pomodoro
                systemMonitor: panel.systemMonitor

                onPopupClosed: function(popup) {
                    bar.statusPopupClosed(popup, panel);
                }

                onAudioSinkSelected: function(sink) {
                    bar.audioSinkSelected(sink);
                }
            }

        }
    }
}
