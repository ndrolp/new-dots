import Quickshell.Io
import QtQuick
import "../components/panels" as Panels
import "../services/QuickSwitch.js" as QuickSwitch

// The quick switch on SUPER+P. Applying only starts the change: the service runs the Keep or Revert
// countdown, and Keep saves it.
Feature {
    id: root

    required property var appearance
    required property var monitorSetups

    property int selected: 0

    function moveDown() {
        selected = QuickSwitch.next(selected, monitorSetups.quickSwitchChoices.length);
    }

    // Hyprland keeps SUPER+P however the panel has the keyboard, so with SUPER held it's P moving down.
    function press() {
        if (open) {
            moveDown();
        } else {
            selected = 0;
            show();
        }
    }

    Panels.QuickSwitch {
        appearance: root.appearance
        open: root.open
        choices: root.monitorSetups.quickSwitchChoices
        currentIndex: root.selected

        onSelectionAsked: index => root.selected = index
        onCloseRequested: root.open = false
        onChosen: choice => {
            root.open = false;
            root.monitorSetups.quickSwitch(choice);
        }
    }

    IpcHandler {
        target: "quick-switch"

        function press() {
            root.press();
        }
    }
}
