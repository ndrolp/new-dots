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

// The known devices once every row connected over the network now is
// remembered with its name and address. A device that isn't connected over
// the network keeps what was remembered of it.
function remembered(known, rows) {
    const next = known.map(device => Object.assign({}, device));
    for (const row of rows) {
        if (row.state !== "wifi" && row.state !== "both")
            continue;
        const entry = next.find(device => device.serial === row.serial);
        if (entry) {
            entry.model = row.name;
            if (row.wifiAddress !== "")
                entry.address = row.wifiAddress;
        } else {
            next.push({ serial: row.serial, model: row.name, address: row.wifiAddress });
        }
    }
    return next;
}

function forgotten(known, serial) {
    return known.filter(device => device.serial !== serial);
}

// The addresses Connect tries, in order: the one mDNS announces now, then
// the last one remembered.
function connectAddresses(row, known) {
    const entry = known.find(device => device.serial === row.serial);
    const addresses = [row.announced, entry ? entry.address : ""];
    return addresses.filter((address, index) => address !== "" && addresses.indexOf(address) === index);
}

// What `adb connect <address>` printed: "connected", "unpaired" (the phone
// answered but isn't paired with this computer) or "unreachable".
function connectOutcome(output) {
    const text = String(output || "");
    if (/\bconnected to\b/.test(text) && !/failed/.test(text))
        return "connected";
    if (/failed to authenticate/.test(text))
        return "unpaired";
    return "unreachable";
}

// The outcome to report after every address failed: not paired says more
// than not answering.
function worstOutcome(outcomes) {
    return outcomes.indexOf("unpaired") >= 0 ? "unpaired" : "unreachable";
}

function connectProblem(outcome) {
    if (outcome === "unpaired")
        return "Not paired with this computer: pair it below";
    if (outcome === "unreachable")
        return "Turn on Wireless debugging on the phone";
    return "";
}

const alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789";

function randomText(random, length) {
    let text = "";
    for (let index = 0; index < length; index++)
        text += alphabet.charAt(Math.floor(random() * alphabet.length) % alphabet.length);
    return text;
}

// A fresh service name and password for the QR code, from `random` (Math.random).
// Letters and digits only, so the payload needs no escaping.
function qrPairing(random) {
    return { name: "studio-" + randomText(random, 8), password: randomText(random, 12) };
}

// What the QR code holds: the phone's "Pair device with QR code" reads it,
// then announces a pairing service under `name` and waits for adb pair
// with `password`.
function qrPayload(pairing) {
    return "WIFI:T:ADB;S:" + pairing.name + ";P:" + pairing.password + ";;";
}

// The address of the pairing service called `name` ("" until it is announced).
function pairingAddress(services, name) {
    const service = services.find(entry => entry.type === "pairing" && entry.name === name);
    return service ? service.address : "";
}

// The address a phone showing its pairing code dialog announces: its own
// pairing service ("adb-<serial>-…"), not a QR code's. "" when there is none.
function codePairingAddress(services) {
    const service = services.find(entry => entry.type === "pairing" && serialOf(entry.name) !== entry.name);
    return service ? service.address : "";
}

function canPairWithCode(address, code) {
    return /^\S+:\d+$/.test(String(address).trim()) && /^\d{6}$/.test(String(code).trim());
}

// The hardware serial of the phone `adb pair` paired with, from the guid it
// prints on success ("" when it failed).
function pairedSerial(output) {
    const match = /Successfully paired to \S+ \[guid=([^\]\s]+)\]/.exec(String(output || ""));
    return match ? serialOf(match[1]) : "";
}

function pairProblem(output) {
    const line = String(output || "").split("\n").map(text => text.trim()).find(text => text !== "");
    return line ? line.replace(/^Failed:\s*/, "") : "Couldn't pair with the phone";
}

// The phone's Wi-Fi IPv4 address, from `ip -f inet addr show wlan0` ("" if none).
function wifiIp(output) {
    const match = /\binet (\d+\.\d+\.\d+\.\d+)\//.exec(String(output || ""));
    return match ? match[1] : "";
}
