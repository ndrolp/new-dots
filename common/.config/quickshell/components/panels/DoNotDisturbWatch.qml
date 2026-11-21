import QtQuick
import "OsdChange.js" as OsdChange

// Do Not Disturb as a change event: `toggled` gives the change (see
// OsdChange.doNotDisturb) each time it is turned on or off, from anywhere.
// The setting read from appearance.json as the shell starts is how it already
// was, not a change, so nothing shows until `appearance` has loaded.
QtObject {
    id: root

    // Anything with `loaded` and `doNotDisturb` (config/Appearance.qml).
    property var appearance: null
    readonly property bool loaded: appearance ? appearance.loaded === true : false
    readonly property bool doNotDisturb: appearance ? appearance.doNotDisturb === true : false
    // Do Not Disturb as last seen, and whether it has been seen once.
    property bool lastSeen: false
    property bool seenOnce: false

    signal toggled(var change)

    function check() {
        if (!loaded)
            return;
        if (seenOnce && doNotDisturb !== lastSeen)
            toggled(OsdChange.doNotDisturb(doNotDisturb));
        lastSeen = doNotDisturb;
        seenOnce = true;
    }

    onLoadedChanged: check()
    onDoNotDisturbChanged: check()
    Component.onCompleted: check()
}
