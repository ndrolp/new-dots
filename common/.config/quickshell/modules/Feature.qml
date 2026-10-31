import Quickshell
import QtQuick
import "SwitchTo.js" as SwitchTo

// A part of the shell that opens and closes: it owns whether it is open, and
// the panel and IPC handler declared inside it follow `open`. A feature
// behind a plugin passes the plugin's switch as `available`; while it is off
// the feature stays closed and its IPC toggle does nothing.
Scope {
    id: root

    property bool open: false
    property bool available: true

    // Whatever opens it, it stays closed while unavailable, so the panel
    // inside can follow `open` alone.
    onAvailableChanged: {
        if (!available)
            open = false;
    }
    onOpenChanged: {
        if (open && !available)
            open = false;
    }

    function toggle() {
        if (!available)
            return;

        open = !open;
    }

    // Opens it (what another part calls to open it in its place).
    function show() {
        open = true;
    }

    // Closes this feature and opens `other` (anything with `available` and
    // `show()`) in its place, unless `other`'s plugin is off, in which case
    // this one stays open.
    function switchTo(other) {
        SwitchTo.switchTo(() => root.open = false, other);
    }
}
