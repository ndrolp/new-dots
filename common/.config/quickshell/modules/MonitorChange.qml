import Quickshell
import Quickshell.Wayland
import QtQuick
import "../components/panels" as Panels
import "../config" as Config

// What a change of monitors puts on the screens themselves: the Keep or Revert card, on every screen
// that still works so it can't end up only on a black one, and each monitor's number for Identify.
// Quickshell only has screens that are on, so a monitor just turned off gets neither.
Scope {
    id: root

    required property var appearance
    required property var monitorSetups

    Config.Theme {
        id: theme
    }

    Variants {
        model: Quickshell.screens

        delegate: PanelWindow {
            required property var modelData

            screen: modelData
            visible: root.monitorSetups.counting
            anchors.top: true
            margins.top: 48
            implicitWidth: card.width
            implicitHeight: card.height
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.namespace: "ndro-shell-monitor-change"
            WlrLayershell.layer: WlrLayer.Overlay

            Panels.MonitorChangeCard {
                id: card

                appearance: root.appearance
                secondsLeft: root.monitorSetups.secondsLeft
                onKeepAsked: root.monitorSetups.keep()
                onRevertAsked: root.monitorSetups.revert()
            }
        }
    }

    Variants {
        model: Quickshell.screens

        delegate: PanelWindow {
            required property var modelData

            screen: modelData
            visible: root.monitorSetups.identifying
            implicitWidth: 180
            implicitHeight: 180
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.namespace: "ndro-shell-monitor-number"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
            mask: Region {}

            Rectangle {
                anchors.fill: parent
                radius: root.appearance.radius
                color: theme.surface
                border.color: theme.accent
                border.width: 2

                Panels.Text {
                    anchors.centerIn: parent
                    text: root.monitorSetups.numberOf(modelData.name)
                    color: theme.text
                    font.pixelSize: 96
                }
            }
        }
    }
}
