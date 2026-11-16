.pragma library
.import "AndroidDevices.js" as Android

// Pairing a new Android device for the Android devices panel: the QR code
// it scans, the pairing services it announces over mDNS, what `adb pair`
// answered, and what to say when the device paired but didn't connect.
// Pure, no Quickshell; AndroidPairing.qml runs adb and qrencode.

const missingQrencode = "qrencode isn't installed, so the QR code can't be drawn. "
    + "Install qrencode, or use a pairing code.";

function pairCommand(address, password) {
    return ["adb", "pair", address, password];
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

const alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789";

function randomText(random, length) {
    let text = "";
    for (let index = 0; index < length; index++)
        text += alphabet.charAt(Math.floor(random() * alphabet.length) % alphabet.length);
    return text;
}

// The start of a QR code's service name. Android Studio names its QR
// pairing services "studio-…"; the same prefix keeps them apart from the
// "adb-<serial>-…" services an Android device announces itself.
const qrServicePrefix = "studio-";

// A fresh service name and password for the QR code, from `random` (Math.random).
// Letters and digits only, so the payload needs no escaping.
function qrPairing(random) {
    return { name: qrServicePrefix + randomText(random, 8), password: randomText(random, 12) };
}

// What the QR code holds: the Android device's "Pair device with QR code"
// reads it, then announces a pairing service under `name` and waits for
// adb pair with `password`.
function qrPayload(pairing) {
    return "WIFI:T:ADB;S:" + pairing.name + ";P:" + pairing.password + ";;";
}

// The address of the pairing service called `name` ("" until it is announced).
function pairingAddress(services, name) {
    const service = services.find(entry => entry.type === "pairing" && entry.name === name);
    return service ? service.address : "";
}

// The address an Android device showing its pairing code dialog announces:
// its own pairing service ("adb-<serial>-…"), not a QR code's. "" when there
// is none.
function codePairingAddress(services) {
    const service = services.find(entry => entry.type === "pairing"
        && Android.serialOf(entry.name) !== entry.name);
    return service ? service.address : "";
}

function canPairWithCode(address, code) {
    return /^\S+:\d+$/.test(String(address).trim()) && /^\d{6}$/.test(String(code).trim());
}

// The hardware serial of the Android device `adb pair` paired with, from
// the guid it prints on success ("" when it failed).
function pairedSerial(output) {
    const match = /Successfully paired to \S+ \[guid=([^\]\s]+)\]/.exec(String(output || ""));
    return match ? Android.serialOf(match[1]) : "";
}

function pairProblem(output) {
    const line = String(output || "").split("\n").map(text => text.trim()).find(text => text !== "");
    return line ? line.replace(/^Failed:\s*/, "") : "Couldn't pair with the phone";
}
