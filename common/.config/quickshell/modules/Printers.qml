import Quickshell.Io
import QtQuick
import "../components/panels" as Panels

// The Printers panel (SUPER+SHIFT+P, `printers toggle`): the printers, which
// one is the default, and removing them. The printers service only reads
// CUPS while the panel is open.
Feature {
    id: root

    required property var appearance
    required property var printers
    required property var plugins

    available: plugins.printersEnabled

    Binding {
        target: root.printers
        property: "watching"
        value: root.open
    }

    Panels.PrintersPanel {
        appearance: root.appearance
        printers: root.printers
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
