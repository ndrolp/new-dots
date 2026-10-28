import Quickshell
import Quickshell.Io
import QtQuick
import "../components/panels" as Panels

// The settings panel. It opens attached to the bar it was asked from, or to
// the first bar that came up when IPC or another panel opens it.
Feature {
    id: root

    required property var appearance
    required property var monitors
    required property var wallpapers
    required property var bookmarks
    required property var plugins
    required property var cava

    property var screen: null
    property var window: null

    onOpenChanged: {
        if (open && screen === null)
            screen = Quickshell.screens.values[0];
    }

    // The settings button on a bar: closes the panel if it is open on that
    // bar, otherwise opens it there.
    function toggleOn(barScreen, panelWindow) {
        if (open && window === panelWindow) {
            open = false;
        } else {
            screen = barScreen;
            window = panelWindow;
            open = true;
        }
    }

    // A bar came up: the panel attaches to the first one until asked from
    // another.
    function offerWindow(barScreen, panelWindow) {
        if (window !== null)
            return;

        screen = barScreen;
        window = panelWindow;
    }

    Panels.ConfigPanelWindow {
        appearance: root.appearance
        monitors: root.monitors
        wallpapers: root.wallpapers
        bookmarks: root.bookmarks
        plugins: root.plugins
        cava: root.cava
        open: root.open
        targetWindow: root.window

        onCloseRequested: root.open = false
    }

    IpcHandler {
        target: "config"

        function toggle() {
            root.toggle();
        }
    }
}
