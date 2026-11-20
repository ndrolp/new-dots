import Quickshell.Io
import QtQuick
import "../components/panels" as Panels
import "OpenPopup.js" as OpenPopup

// The wallpaper picker. On a monitor whose bar is a capsule it opens inside
// the capsule as its popup (components/panels/WallpaperPopup.qml), which
// previews each wallpaper on the desktop; on any other bar it is the
// full-screen picker.
Feature {
    id: root

    required property var appearance
    required property var wallpapers
    // The bar module, which opens and closes popups on the bars.
    required property var bar

    readonly property string popupName: "wallpapers"

    // The focused bar's capsule, or null when the picker is full-screen.
    function capsule() {
        return OpenPopup.focusedCapsule(bar.bars(), bar.focusedMonitor());
    }

    function toggle() {
        if (!available)
            return;
        if (capsule() === null) {
            open = !open;
            return;
        }
        open = false;
        bar.openPopup = OpenPopup.toggledOnFocusedBar(bar.openPopup, popupName,
            bar.bars(), bar.focusedMonitor());
    }

    function show() {
        if (capsule() === null) {
            open = true;
            return;
        }
        open = false;
        bar.openPopup = OpenPopup.openedOnFocusedBar(bar.openPopup, popupName,
            bar.bars(), bar.focusedMonitor());
    }

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
    }
}
