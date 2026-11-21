import Quickshell
import Quickshell.Services.UPower
import QtQuick
import "../components/panels/OsdChange.js" as OsdChange
import "../services/PowerChange.js" as PowerChange

// The power change events: plugging the charger in or out, and the battery
// reaching 15% while discharging, shown through the OSD module (in the
// focused monitor's capsule, or the OSD). Which reading makes which event is
// services/PowerChange.js; the low-battery notification (LowBattery.qml)
// stays as it is.
Scope {
    id: root

    // The OSD module (modules/Osd.qml).
    required property var osd

    readonly property var battery: UPower.displayDevice
    readonly property var reading: PowerChange.reading(battery ? {
        isPresent: battery.isPresent,
        state: battery.state,
        percentage: battery.percentage
    } : null, UPowerDeviceState)
    // The last state, null before the first reading (see PowerChange.next).
    property var powerState: null

    function read() {
        const next = PowerChange.next(root.powerState, root.reading);
        root.powerState = next.state;
        if (next.event)
            root.osd.show(OsdChange.power(next.event));
    }

    onReadingChanged: read()
    Component.onCompleted: read()
}
