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

// The name to show: the device's own name, else its alias. Never an address.
function label(device) {
    if (isRealName(device, device.deviceName))
        return device.deviceName;
    if (isRealName(device, device.name))
        return device.name;
    return "Unknown device";
}

// 0 for connected, 1 for paired, 2 for newly found.
function rank(device) {
    return device.connected ? 0 : device.paired ? 1 : 2;
}

// Devices to list: paired and connected ones always, found ones once their
// name has arrived. Connected first, then paired, then found; the sort is
// stable, so each group keeps the adapter's order.
function visibleDevices(devices) {
    return Array.from(devices)
        .filter(device => isKnown(device) || isRealName(device, device.deviceName))
        .sort((a, b) => rank(a) - rank(b));
}
