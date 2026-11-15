import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import QtQuick
import "../../config" as Config
import "." as Panels

// The Printers panel's window: a card in the centre of the focused monitor
// with one list under headings. *Printers* (PrintersSection.qml) is the
// first; *Discovered printers* and *Scanners* go below it in `sections`.
// It shows what the printers service reads and asks it for every change.
Variants {
    id: root

    required property var appearance
    required property var printers
    required property var discoveredPrinters
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

        screen: modelData
        visible: root.open && focusedMonitor
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        focusable: true
        WlrLayershell.namespace: "ndro-shell-printers"
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
                    printersSection.expanded = "";
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

                    Panels.PrintersSection {
                        id: printersSection

                        width: parent.width
                        appearance: root.appearance
                        printers: root.printers.printers
                        failure: root.printers.failure
                        busy: root.printers.changing
                        onSetDefaultRequested: name => root.printers.setDefault(name)
                        onRemoveRequested: name => root.printers.remove(name)
                    }

                    Panels.DiscoveredPrintersSection {
                        width: parent.width
                        appearance: root.appearance
                        discovered: root.discoveredPrinters.discovered
                        problem: root.discoveredPrinters.problem
                        adding: root.discoveredPrinters.adding
                        addFailureKey: root.discoveredPrinters.addFailureKey
                        addFailure: root.discoveredPrinters.addFailure
                        onAddRequested: printer => root.discoveredPrinters.add(printer)
                        onPrintSettingsRequested: root.discoveredPrinters.openPrintSettings()
                    }
                }
            }
        }
    }
}
