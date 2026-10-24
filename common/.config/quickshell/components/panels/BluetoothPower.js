.pragma library

// Turning Bluetooth on and off, shared by the Bluetooth popup and the Control
// center: pure logic, no Quickshell. BluetoothPower.qml carries it out.

// What turning Bluetooth on (`on`) or off takes: "disable", "enable", or
// "unblock" with rfkill first when the adapter is blocked, then enable.
function step(on, blocked) {
    if (!on)
        return "disable";

    return blocked ? "unblock" : "enable";
}

// Why turning Bluetooth on failed. Takes { unblockFailed (rfkill exited with
// an error), blocked (the adapter is still blocked) }.
function failure(attempt) {
    if (attempt.unblockFailed)
        return "Couldn't unblock Bluetooth (rfkill)";

    return attempt.blocked ? "Bluetooth is blocked (rfkill)" : "Couldn't turn Bluetooth on";
}
