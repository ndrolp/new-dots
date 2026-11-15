import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import QtQuick
import "../../config" as Config
import "." as Panels

// The Printers panel's window: a card in the centre of the focused monitor
// with one list under headings. *Printers* (PrintersSection.qml) is the
// first; *Discovered printers* and *Scanners* (ScannersSection.qml) go
// below it in `sections`. A scanner's *Scan…* swaps the list for its scan
// view (ScanView.qml) until *Back*.
// It shows what the printers service reads and asks it for every change.
Variants {
    id: root

    required property var appearance
    required property var printers
    required property var discoveredPrinters
    required property var scanners
    property bool open: false

    signal closeRequested()

    model: Quickshell.screens

    delegate: PanelWindow {
        id: panel

        required property var modelData
        // The scanner whose scan view is showing, or null for the list.
        property var scanTarget: null
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
            if (visible) {
                card.forceActiveFocus();
                root.printers.jobsPrinter = printersSection.expanded;
            }
        }

        Connections {
            target: root

            function onOpenChanged() {
                if (root.open) {
                    printersSection.expanded = "";
                    panel.scanTarget = null;
                }
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
            height: Math.min(parent.height - 80,
                (panel.scanTarget ? scanView.implicitHeight : sections.implicitHeight) + 32)
            radius: root.appearance.radius
            color: Qt.rgba(theme.surface.r, theme.surface.g, theme.surface.b, 0.78)
            border.color: theme.border
            border.width: 1
            focus: true

            // Clicks on the card don't reach the backdrop behind it.
            TapHandler {}

            Keys.onEscapePressed: root.closeRequested()

            Flickable {
                visible: !panel.scanTarget
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
                        jobs: root.printers.jobs
                        onCancelJobRequested: id => root.printers.cancelJob(id)
                        onTestPageRequested: name => root.printers.printTestPage(name)
                        // Only the open printer's print jobs are read.
                        onExpandedChanged: {
                            if (panel.visible)
                                root.printers.jobsPrinter = expanded;
                        }
                    }

                    Panels.DiscoveredPrintersSection {
                        width: parent.width
                        appearance: root.appearance
                        discovered: root.discoveredPrinters.discovered
                        problem: root.discoveredPrinters.problem
                        addState: root.discoveredPrinters.addState
                        onAddRequested: printer => root.discoveredPrinters.add(printer)
                        onPrintSettingsRequested: root.discoveredPrinters.openPrintSettings()
                    }

                    Panels.ScannersSection {
                        width: parent.width
                        appearance: root.appearance
                        scanners: root.scanners.scanners
                        problem: root.scanners.problem
                        onScanRequested: scanner => {
                            root.scanners.readModes(scanner.saneName);
                            panel.scanTarget = scanner;
                        }
                    }
                }
            }

            Panels.ScanView {
                id: scanView

                visible: !!panel.scanTarget
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 16
                appearance: root.appearance
                scanner: panel.scanTarget
                settings: root.scanners.settings
                modes: root.scanners.modes
                scanning: root.scanners.scanning
                progress: root.scanners.progress
                failure: root.scanners.scanFailure
                lastScan: root.scanners.lastScan
                onSettingChosen: (key, value) => root.scanners.setSetting(key, value)
                onScanRequested: root.scanners.scan(panel.scanTarget.saneName)
                onBackRequested: panel.scanTarget = null
            }
        }
    }
}
