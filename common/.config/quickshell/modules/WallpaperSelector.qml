import Quickshell.Io
import QtQuick
import "../components/panels" as Panels

// The wallpaper picker. On a monitor whose bar is a capsule it opens inside
// the capsule as its popup (components/panels/WallpaperPopup.qml), which
// previews each wallpaper on the desktop; on any other bar it is the
// full-screen picker (CapsuleFeature).
CapsuleFeature {
    id: root

    required property var appearance
    required property var wallpapers

    popupName: "wallpapers"

    Panels.WallpaperSelector {
        appearance: root.appearance
        wallpapers: root.wallpapers
        open: root.open

        onCloseRequested: root.open = false
    }

    IpcHandler {
        target: "wallpapers"

        function toggle() {
            root.toggle();
        }

        // The colorscheme changer applied `colorscheme`: its wallpapers.
        function colorscheme(colorscheme: string): void {
            root.wallpapers.useColorscheme(colorscheme);
        }
    }
}
