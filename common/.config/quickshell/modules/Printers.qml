import Quickshell.Io
import QtQuick
import "../components/panels" as Panels
import "../services" as Services

// The Printers panel (SUPER+SHIFT+P, `printers toggle`): the printers, which
// one is the default, removing them and adding the ones found on the network
// and USB, and the scanners and scanning. The printers, discovered printers
// and scanners services only look while the panel is open.
Feature {
    id: root

    required property var appearance
    required property var printers
    required property var scanners
    required property var plugins

    available: plugins.printersEnabled

    Binding {
        target: root.printers
        property: "watching"
        value: root.open
    }

    // Looks for printers to add only while the panel is open.
    Services.DiscoveredPrinters {
        id: discoveredPrinters

        watching: root.open
        printers: root.printers.printers
        onAdded: root.printers.refresh()
    }

    Binding {
        target: root.scanners
        property: "watching"
        value: root.open
    }

    Panels.PrintersPanel {
        appearance: root.appearance
        printers: root.printers
        discoveredPrinters: discoveredPrinters
        scanners: root.scanners
        open: root.open

        onCloseRequested: root.open = false
    }

    IpcHandler {
        target: "printers"

        function toggle() {
            root.toggle();
        }
    }
}
