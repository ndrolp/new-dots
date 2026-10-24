.pragma library

// Bluetooth device list for the Bluetooth popup: pure logic, no Quickshell.
// Devices are Quickshell BluetoothDevice objects, or anything with the same
// `deviceName`, `name`, `address`, `paired` and `connected` fields.

// BlueZ sets the alias (`name`) to the address, colons or dashes, when the
// device sent no name.
function isAddress(text) {
    return /^([0-9A-F]{2}[:-]){5}[0-9A-F]{2}$/i.test(text);
}

function isRealName(device, text) {
    return !!text && text !== device.address && !isAddress(text);
}

function isKnown(device) {
    return device.paired || device.connected;
}

function isNamed(device) {
    return isRealName(device, device.deviceName) || isRealName(device, device.name);
}

// The name to show: the device's own name, else its alias. Never an address.
function label(device) {
    if (isRealName(device, device.deviceName))
        return device.deviceName;
    if (isRealName(device, device.name))
        return device.name;
    return "Unnamed device";
}

// Tells unnamed devices apart: the last two bytes of the address, e.g.
// "DC:59". Empty for a named device.
function identifier(device) {
    if (isNamed(device))
        return "";
    return device.address.toUpperCase().split(/[:-]/).slice(-2).join(":");
}

// Unnamed devices that aren't yours are shown faded.
function isDimmed(device) {
    return !isKnown(device) && !isNamed(device);
}

// 0 for connected, 1 for paired, 2 for found with a name, 3 for unnamed.
function rank(device) {
    return device.connected ? 0 : device.paired ? 1 : isNamed(device) ? 2 : 3;
}

// Every device, connected first, then paired, then found, then unnamed; the
// sort is stable, so each group keeps the adapter's order.
function visibleDevices(devices) {
    return Array.from(devices).sort((a, b) => rank(a) - rank(b));
}
