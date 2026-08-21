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
    required property var workspaceService

    signal configRequested(var screen, var panelWindow)
    signal panelReady(var screen, var panelWindow)
    signal statusPopupRequested(string popup, var panelWindow)
    signal statusPopupClosed(string popup, var panelWindow)

    model: Quickshell.screens

    delegate: Component {
        PanelWindow {
            id: panel

            required property var modelData
            property var appearance: bar.appearance
            property bool configOpen: bar.configOpen
            property string activeStatusPopup: bar.activeStatusPopupWindow === panel
                ? bar.activeStatusPopup : ""
            property var monitors: bar.monitors
            property var workspaceService: bar.workspaceService

            Component.onCompleted: bar.panelReady(panel.screen, panel)

            screen: modelData
            WlrLayershell.namespace: "ndro-shell-bar"
            color: "transparent"
            mask: Region {
                x: 0
                y: 0
                width: panel.width
                height: panel.height
            }
            readonly property int totalBarHeight: panel.appearance.barHeight
                + (panel.appearance.barTransparent ? panel.appearance.transparentBarTopMargin : 0)

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
                color: panel.appearance.barTransparent ? "transparent" : theme.background

                Behavior on color {
                    ColorAnimation {
                        duration: 220
                        easing.type: Easing.OutCubic
                    }
                }

                BarContent {
                    id: barContent

                    anchors.fill: parent
                    anchors.leftMargin: panel.appearance.horizontalPadding
                    anchors.rightMargin: panel.appearance.horizontalPadding
                    anchors.topMargin: panel.appearance.barTransparent
                        ? panel.appearance.transparentBarTopMargin : 0
                    appearance: panel.appearance
                    configOpen: panel.configOpen
                    monitorScreen: panel.screen
                    monitors: panel.monitors
                    workspaceService: panel.workspaceService

                    onConfigRequested: function(screen) {
                        bar.configRequested(screen, panel);
                    }

                    onStatusPopupRequested: function(popup) {
                        bar.statusPopupRequested(popup, panel);
                    }
                }
            }

            Panels.StatusPopups {
                appearance: panel.appearance
                barWindow: panel
                activePopup: panel.activeStatusPopup

                onPopupClosed: function(popup) {
                    bar.statusPopupClosed(popup, panel);
                }
            }

        }
    }
}
