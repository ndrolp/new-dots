.pragma library

// The Android devices panel's rules: reading what adb prints, merging live
// Android devices with known devices into one row each, choosing the address
// Connect uses, and the QR code that pairs a phone. Pure, no Quickshell;
// AndroidDevices.qml runs adb.

// Whatever adb is on PATH; no SDK path is assumed.
const devicesCommand = ["adb", "devices", "-l"];
const servicesCommand = ["adb", "mdns", "services"];
// Exits 0 when adb (or qrencode) is on PATH.
function toolCheck(tool) {
    return ["sh", "-c", "command -v \"$0\" >/dev/null", tool];
}
const missingAdb = "adb isn't installed, so Android devices can't be listed or connected. "
    + "Install android-tools.";
const missingQrencode = "qrencode isn't installed, so the QR code can't be drawn. "
    + "Install qrencode, or use a pairing code.";

function connectCommand(address) {
    return ["adb", "connect", address];
}

function disconnectCommand(transports) {
    return ["sh", "-c", "for transport; do adb disconnect \"$transport\"; done", "sh"].concat(transports);
}

function pairCommand(address, password) {
    return ["adb", "pair", address, password];
}

// What a network transport reports as its hardware serial.
function serialCommand(transport) {
    return ["adb", "-s", transport, "shell", "getprop", "ro.serialno"];
}

// From USB: the Android device's Wi-Fi address (read with wifiIp), then adbd
// listening on the network. The interface isn't assumed to be wlan0: it
// prints the default route, then every IPv4 address.
const tcpipPort = 5555;
function wifiIpCommand(serial) {
    return ["adb", "-s", serial, "shell", "ip route get 1.1.1.1; ip -f inet addr show"];
}
function tcpipCommand(serial) {
    return ["adb", "-s", serial, "tcpip", String(tcpipPort)];
}

// `command` with stderr folded into stdout: adb prints some answers on one
// and some on the other.
function merged(command) {
    return ["sh", "-c", "exec \"$@\" 2>&1", "sh"].concat(command);
}

// Where the QR code for `name` is drawn, in `dir` (the runtime directory).
function qrPath(dir, name) {
    return dir + "/quickshell-android-pairing-" + name + ".png";
}

// Removes the old QR codes in `dir` and draws `payload` at `path`. It runs
// through sh, which exits 127 when it can't find qrencode.
function qrCommand(dir, path, payload) {
    return ["sh", "-c", "rm -f \"$0\"/quickshell-android-pairing-*.png; exec qrencode -s 6 -m 2 -o \"$1\" \"$2\"",
        dir, path, payload];
}

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

// The network transports deviceSerial can't place: connected ones named
// after a bare ip:port nobody knows. Each is asked with serialCommand.
function unplacedTransports(devices, known, serials) {
    return devices.filter(device => !device.usb && device.state === "device"
        && deviceSerial(device.transport, known, serials) === device.transport)
        .map(device => device.transport);
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
// USB debugging prompt offers nothing until it is accepted. One connected
// over the network would be remembered again at once, so it offers
// Disconnect and not Forget.
function actions(row) {
    const offered = [];
    const wifi = row.state === "wifi" || row.state === "both";
    if (row.state === "available" || row.state === "notSeen")
        offered.push("connect");
    if (wifi)
        offered.push("disconnect");
    if (row.known && !wifi)
        offered.push("forget");
    if (row.state === "usb" && row.authorized)
        offered.push("connectWirelessly");
    return offered;
}

// The known devices once every row connected over the network now is
// remembered with its name and address. A device that isn't connected over
// the network keeps what was remembered of it, and one whose serial isn't
// known yet (its ip:port stands in until `getprop ro.serialno` answers)
// waits for it.
function remembered(known, rows) {
    const next = known.map(device => Object.assign({}, device));
    for (const row of rows) {
        if (row.state !== "wifi" && row.state !== "both")
            continue;
        if (row.wifi.indexOf(row.serial) >= 0)
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

// What `adb connect <address>` printed: "connected", "unpaired" (the
// Android device answered but isn't paired with this computer),
// "unreachable" (nothing answered there) or "unknown" (it failed without
// saying why). adb's wording varies between versions, so it is matched
// loosely.
function connectOutcome(output) {
    const text = String(output || "");
    if (/\bconnected to\b/i.test(text) && !/fail|cannot|unable/i.test(text))
        return "connected";
    if (/authenticat|unauthori[sz]ed|not paired|pairing|\btls\b|handshake|certificate/i.test(text))
        return "unpaired";
    if (/refused|timed? ?out|no route|unreachable|network|no such host|host is down|resolve/i.test(text))
        return "unreachable";
    return "unknown";
}

// The outcome to report after every address failed: not paired says more
// than not answering, and a failure that didn't say why could be either.
function worstOutcome(outcomes) {
    for (const outcome of ["unpaired", "unknown"]) {
        if (outcomes.indexOf(outcome) >= 0)
            return outcome;
    }
    return "unreachable";
}

const connectProblems = {
    unpaired: "Not paired with this computer: pair it below",
    unreachable: "Turn on Wireless debugging on the phone",
    unknown: "Couldn't connect: turn on Wireless debugging on the phone, "
        + "or pair it below if it isn't paired with this computer"
};

function connectProblem(outcome) {
    return connectProblems[outcome] || "";
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

// Interfaces for mobile data (Qualcomm's rmnet, MediaTek's ccmni): this
// computer can't be reached through them.
const mobileInterface = /^(rmnet|ccmni)/;

// The Android device's Wi-Fi IPv4 address from what wifiIpCommand prints
// ("" if none): the source address of its default route, unless that goes
// over mobile data, else the address of any wlan* interface.
function wifiIp(output) {
    const text = String(output || "");
    const route = /\bdev (\S+)\b.*\bsrc (\d+\.\d+\.\d+\.\d+)/.exec(text);
    if (route && !mobileInterface.test(route[1]))
        return route[2];
    const wlan = /^\s*inet (\d+\.\d+\.\d+\.\d+)\/\d+.*\b(wlan\S*)\s*$/m.exec(text);
    return wlan ? wlan[1] : "";
}
