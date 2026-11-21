.pragma library

// Bluetooth connections as change events: which devices connected or
// disconnected since the last read. Pure, no Quickshell; devices are
// BluetoothDevice objects or anything with `address` and `connected`.

// Reads `devices` against `known` (address -> connected, from the last read;
// {} before any). Returns the new `known` and the devices whose connection
// changed. A device is only told once it has been seen: one connected when
// the shell starts, or first listed already connected, isn't a change.
function read(known, devices) {
    const next = {};
    const changed = [];

    for (const device of Array.from(devices)) {
        const connected = device.connected === true;

        if (known.hasOwnProperty(device.address) && known[device.address] !== connected)
            changed.push(device);
        next[device.address] = connected;
    }
    return { known: next, changed: changed };
}
