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
    // Do Not Disturb as last read, and whether it has been read once.
    property bool last: false
    property bool read: false

    signal toggled(var change)

    function check() {
        if (!loaded)
            return;
        if (read && doNotDisturb !== last)
            toggled(OsdChange.doNotDisturb(doNotDisturb));
        last = doNotDisturb;
        read = true;
    }

    onLoadedChanged: check()
    onDoNotDisturbChanged: check()
    Component.onCompleted: check()
}
