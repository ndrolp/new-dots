import Quickshell.Io
import QtQuick
import "../components/panels" as Panels

// The power menu: full-screen, or inside the capsule on a monitor whose bar
// is one (components/panels/PowerMenuPopup.qml).
CapsuleFeature {
    id: root

    required property var appearance

    popupName: "powerMenu"

    Panels.PowerMenu {
        appearance: root.appearance
        open: root.open

        onCloseRequested: root.open = false
    }

    IpcHandler {
        target: "power"

        function toggle() {
            root.toggle();
        }
    }
}
