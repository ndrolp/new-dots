import Quickshell.Io
import QtQuick
import "../components/panels" as Panels

// The web app maker (SUPER+SHIFT+W, `web-apps toggle`): makes a web app from
// a URL and lists, opens and deletes the ones it made.
Feature {
    id: root

    required property var appearance
    required property var webApps
    required property var plugins

    available: plugins.webAppsEnabled

    Panels.WebAppMaker {
        appearance: root.appearance
        webApps: root.webApps
        open: root.open

        onCloseRequested: root.open = false
    }

    // Here and not in the panel, which has a window on every monitor: a new
    // web app opens once.
    Connections {
        target: root.webApps

        function onCreated(url) {
            root.webApps.launch(url);
            root.open = false;
        }
    }

    IpcHandler {
        target: "web-apps"

        function toggle() {
            root.toggle();
        }
    }
}
