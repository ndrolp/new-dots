import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import QtQuick
import "../../config" as Config
import "." as Panels

// The Android devices panel's window: a card in the centre of the focused
// monitor with the device list (AndroidDevicesSection.qml) and, under it,
// *Pair new device* (AndroidPairingSection.qml). It closes with Escape or a
// click outside the card. It shows what the Android devices service reads
// and asks it for every action.
Variants {
    id: root

    required property var appearance
    required property var androidDevices
    property bool open: false

    signal closeRequested()

    model: Quickshell.screens

    delegate: PanelWindow {
        id: panel

        required property var modelData
        readonly property var monitor: Hyprland.monitorFor(modelData)
        readonly property bool focusedMonitor: Hyprland.focusedWorkspace
            && Hyprland.focusedWorkspace.monitor && monitor
            && Hyprland.focusedWorkspace.monitor.name === monitor.name
        readonly property var service: root.androidDevices

        screen: modelData
        visible: root.open && focusedMonitor
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        focusable: true
        WlrLayershell.namespace: "ndro-shell-android-devices"
        WlrLayershell.layer: WlrLayer.Overlay

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        onVisibleChanged: {
            if (visible)
                card.forceActiveFocus();
        }

        Connections {
            target: root

            function onOpenChanged() {
                if (root.open)
                    pairing.reset();
            }
        }

        Config.Theme {
            id: theme
        }

        Rectangle {
            anchors.fill: parent
            color: "transparent"

            TapHandler {
                onTapped: root.closeRequested()
            }
        }

        Rectangle {
            id: card

            anchors.centerIn: parent
            width: Math.min(parent.width - 64, 520)
            height: Math.min(parent.height - 80, sections.implicitHeight + 32)
            radius: root.appearance.radius
            color: Qt.rgba(theme.surface.r, theme.surface.g, theme.surface.b, 0.78)
            border.color: theme.border
            border.width: 1
            focus: true

            // Clicks on the card don't reach the backdrop behind it.
            TapHandler {}

            Keys.onEscapePressed: root.closeRequested()

            Flickable {
                anchors.fill: parent
                anchors.margins: 16
                contentHeight: sections.implicitHeight
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                Column {
                    id: sections

                    width: parent.width
                    spacing: 16

                    Panels.AndroidDevicesSection {
                        width: parent.width
                        appearance: root.appearance
                        rows: panel.service.rows
                        unavailable: panel.service.adbProblem
                        message: panel.service.message
                        problem: panel.service.problem
                        busy: panel.service.busy
                        onActionRequested: (action, row) => panel.service[action](row)
                    }

                    Panels.AndroidPairingSection {
                        id: pairing

                        width: parent.width
                        visible: panel.service.adbAvailable
                        appearance: root.appearance
                        qrImage: panel.service.qrImage
                        qrProblem: panel.service.qrProblem
                        codeAddress: panel.service.codeAddress
                        paired: panel.service.paired
                        message: panel.service.pairMessage
                        problem: panel.service.pairProblem
                        busy: panel.service.busy
                        onPairWithCodeRequested: (address, code) => panel.service.pairWithCode(address, code)
                        onCloseRequested: root.closeRequested()
                    }
                }
            }
        }
    }
}
