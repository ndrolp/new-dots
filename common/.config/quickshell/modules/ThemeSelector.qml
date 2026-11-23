import Quickshell.Io
import QtQuick
import "../components/panels" as Panels

// The colorscheme selector: full-screen, or inside the capsule on a monitor
// whose bar is one (components/panels/ThemeSelectorPopup.qml).
CapsuleFeature {
    id: root

    required property var appearance
    required property var wallpapers

    popupName: "colorschemes"

    Panels.ThemeSelector {
        appearance: root.appearance
        wallpapers: root.wallpapers
        open: root.open

        onCloseRequested: root.open = false
    }

    IpcHandler {
        target: "themes"

        function toggle() {
            root.toggle();
        }
    }
}
