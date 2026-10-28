import Quickshell
import QtQuick

// A part of the shell that opens and closes: it owns whether it is open, and
// the panel and IPC handler declared inside it follow `open`. A feature
// behind a plugin passes the plugin's switch as `available`; while it is off
// the feature stays closed and its IPC toggle does nothing.
Scope {
    id: root

    property bool open: false
    property bool available: true

    onAvailableChanged: {
        if (!available)
            open = false;
    }

    function toggle() {
        if (!available)
            return;

        open = !open;
    }

    // Closes this feature and opens `other` in its place, unless `other`'s
    // plugin is off, in which case this one stays open.
    function switchTo(other) {
        if (!other.available)
            return;

        open = false;
        other.open = true;
    }
}
