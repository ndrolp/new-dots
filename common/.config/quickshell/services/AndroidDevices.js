.pragma library

// The Android devices panel's rules: reading what adb prints, merging live
// Android devices with known devices into one row each, choosing the address
// Connect uses, and the QR code that pairs a phone. Pure, no Quickshell;
// AndroidDevices.qml runs adb.

// The model adb reports ("Pixel_10a") as a person writes it.
function modelName(model) {
    return String(model || "").replace(/_/g, " ").trim();
}

// `adb devices -l`: [{ transport, state, usb, model }]. `transport` is what
// adb calls the device's serial: the hardware serial over USB, ip:port or an
// mDNS service name over the network. `state` is adb's: device,
// unauthorized, offline…
function parseDevices(text) {
    const devices = [];
    for (const raw of String(text || "").split("\n")) {
        const line = raw.trim();
        if (line === "" || line.startsWith("*") || line.startsWith("List of devices"))
            continue;
        const fields = line.split(/\s+/);
        if (fields.length < 2)
            continue;
        const details = {};
        for (const field of fields.slice(2)) {
            const colon = field.indexOf(":");
            if (colon > 0)
                details[field.slice(0, colon)] = field.slice(colon + 1);
        }
        devices.push({
            transport: fields[0],
            state: fields[1],
            usb: details.usb !== undefined,
            model: modelName(details.model)
        });
    }
    return devices;
}

// The mDNS service types the panel uses: a phone with Wireless debugging on
// announces "connect"; one showing its pairing dialog (or the QR code's
// service) announces "pairing".
const serviceTypes = {
    "_adb-tls-connect._tcp": "connect",
    "_adb-tls-pairing._tcp": "pairing"
};

// `adb mdns services`: [{ name, type, address }], only connect and pairing
// services. adb prints one tab-separated line each: name, type, ip:port.
function parseServices(text) {
    const services = [];
    for (const raw of String(text || "").split("\n")) {
        const fields = raw.trim().split(/\s+/);
        if (fields.length < 3)
            continue;
        const type = serviceTypes[fields[1].replace(/\.$/, "")];
        if (type)
            services.push({ name: fields[0], type: type, address: fields[2] });
    }
    return services;
}

// The hardware serial in a service name ("adb-<serial>-<random>") or in the
// transport adb names after one ("adb-<serial>-<random>._adb-tls-connect._tcp").
// Anything else (a USB serial, an ip:port) comes back as it is.
function serialOf(name) {
    const service = String(name).replace(/\._adb-tls-[a-z]+\._tcp\.?$/, "");
    const match = /^adb-(.+)-[^-]+$/.exec(service);
    return match ? match[1] : service;
}

// Which Android device a transport is, by hardware serial: the one in its
// name, the one it reported (`serials`: { transport: serial }, read with
// serialCommand), or the known device last connected at that address.
function deviceSerial(transport, known, serials) {
    if (serials[transport])
        return serials[transport];
    const named = serialOf(transport);
    if (named !== transport)
        return named;
    const device = known.find(entry => entry.address === transport);
    return device ? device.serial : transport;
}

// One row per Android device, merging the live devices (parseDevices), the
// mDNS services (parseServices) and the known devices ([{ serial, model,
// address }]): [{ serial, name, state, authorized, wifi, wifiAddress,
// announced, known }].
// - state: "usb", "wifi" or "both" (connected), "available" (announced over
//   mDNS but not connected) or "notSeen" (a known device not visible now).
// - authorized: false for a USB device still waiting for the USB debugging prompt.
// - wifi: the network transports connected to it, and wifiAddress the
//   address of the first (what is remembered of it).
// - announced: the address its connect service announces now ("" if none).
// Live devices come first, in adb's order, then the announced ones, then
// the known devices not seen.
function rows(devices, services, known, serials) {
    const bySerial = {};
    const order = [];
    function row(serial) {
        if (!bySerial[serial]) {
            const entry = known.find(device => device.serial === serial);
            bySerial[serial] = {
                serial: serial, model: "", knownModel: entry ? entry.model : "",
                usb: "", wifi: [], wifiAddress: "", announced: "", known: !!entry
            };
            order.push(serial);
        }
        return bySerial[serial];
    }
    for (const device of devices) {
        const entry = row(deviceSerial(device.transport, known, serials));
        if (device.model)
            entry.model = device.model;
        if (device.usb) {
            entry.usb = device.state;
        } else if (device.state === "device") {
            entry.wifi.push(device.transport);
            if (entry.wifiAddress === "")
                entry.wifiAddress = device.transport;
        }
    }
    for (const service of services) {
        if (service.type === "connect")
            row(serialOf(service.name)).announced = service.address;
    }
    for (const device of known)
        row(device.serial);

    return order.map(serial => {
        const entry = bySerial[serial];
        if (entry.wifiAddress !== "" && serialOf(entry.wifiAddress) !== entry.wifiAddress)
            entry.wifiAddress = entry.announced;
        const usb = entry.usb !== "";
        const wifi = entry.wifi.length > 0;
        return {
            serial: serial,
            name: entry.model || entry.knownModel || serial,
            state: usb && wifi ? "both" : usb ? "usb" : wifi ? "wifi"
                : entry.announced !== "" ? "available" : "notSeen",
            authorized: !usb || entry.usb === "device",
            wifi: entry.wifi,
            wifiAddress: entry.wifiAddress,
            announced: entry.announced,
            known: entry.known
        };
    }).filter(entry => entry.state !== "notSeen" || entry.known);
}

const stateTexts = {
    usb: "Connected · USB",
    wifi: "Connected · Wi-Fi",
    both: "USB + Wi-Fi",
    available: "Available",
    notSeen: "Not seen"
};

function stateText(row) {
    return stateTexts[row.state] || "";
}

// What a row offers: "connect", "disconnect", "forget" and
// "connectWirelessly", in that order. A USB device still waiting for the
// USB debugging prompt offers nothing until it is accepted.
function actions(row) {
    const offered = [];
    if (row.state === "available" || row.state === "notSeen")
        offered.push("connect");
    if (row.state === "wifi" || row.state === "both")
        offered.push("disconnect");
    if (row.known)
        offered.push("forget");
    if (row.state === "usb" && row.authorized)
        offered.push("connectWirelessly");
    return offered;
}
