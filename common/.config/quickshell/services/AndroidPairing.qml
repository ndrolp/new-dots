import Quickshell
import Quickshell.Io
import QtQuick
import "AndroidDevices.js" as Android
import "AndroidPairing.js" as Pairing

// Pairing a new Android device for the Android devices panel, with a QR
// code or the Android device's pairing code, and connecting it once it
// paired. It reads what mDNS announces from the Android devices service
// (`devices`), which also connects the paired Android device. A fresh QR
// code is drawn on every open (`watching`). The rules are in
// AndroidPairing.js; this only runs adb pair and qrencode.
QtObject {
    id: root

    // The Android devices service.
    required property var devices
    property bool watching: false

    // The QR code's service name and password (fresh on every open) and the
    // drawn code ("" until drawn).
    property var qr: ({ name: "", password: "" })
    property string qrImage: ""
    property bool qrencodeAvailable: true
    readonly property string qrProblem: qrencodeAvailable ? "" : Pairing.missingQrencode
    // True once an Android device paired; the QR code is hidden until the next open.
    property bool paired: false
    // What pairing did, or why it failed ("" otherwise).
    property string message: ""
    property string problem: ""
    // While adb pair runs; `busy` also while the Android devices service runs
    // an action, since both use adb.
    property bool pairing: false
    readonly property bool busy: pairing || devices.busy
    // The Android device just paired, waiting to be connected ("" for none),
    // and the address already tried for it.
    property string pairedSerial: ""
    property string pairedAddressTried: ""
    // What an Android device showing its pairing code dialog announces ("" otherwise).
    readonly property string codeAddress: Pairing.codePairingAddress(devices.services)

    // Pairs with the pairing service at `address`, then connects the Android
    // device once it announces itself.
    function pair(address, password) {
        if (busy)
            return;
        pairing = true;
        message = "";
        problem = "";
        pairProcess.password = password;
        pairProcess.command = Android.merged(Pairing.pairCommand(address.trim(), password.trim()));
        pairProcess.running = true;
    }

    // What `adb pair` printed, for `password`.
    function pairDone(output, password) {
        const serial = Pairing.pairedSerial(output);
        if (serial === "") {
            problem = Pairing.pairProblem(output);
            // A QR code is only good for one try.
            if (password === qr.password)
                newQrCode();
        } else {
            pairedSerial = serial;
            pairedAddressTried = "";
            message = "Paired, connecting…";
            connectWait.restart();
        }
        pairing = false;
        devices.refresh();
    }

    function pairWithCode(address, code) {
        if (Pairing.canPairWithCode(address, code))
            pair(address, code);
    }

    function newQrCode() {
        const dir = Quickshell.env("XDG_RUNTIME_DIR") || "/tmp";
        qr = Pairing.qrPairing(Math.random);
        qrImage = "";
        qrProcess.path = Pairing.qrPath(dir, qr.name);
        qrProcess.command = Pairing.qrCommand(dir, qrProcess.path, Pairing.qrPayload(qr));
        qrProcess.running = true;
    }

    // The Android device that scanned the QR code announces its name: pair with it.
    function followQrCode() {
        if (!watching || paired || pairedSerial !== "" || busy || qr.name === "")
            return;
        const address = Pairing.pairingAddress(devices.services, qr.name);
        if (address !== "")
            pair(address, qr.password);
    }

    // The Android device just paired is connected once it announces itself
    // (unless adb already connected it); then pairing says which one it was,
    // or why it didn't connect.
    function followPairedDevice() {
        if (pairedSerial === "")
            return;
        const row = devices.rowFor(pairedSerial);
        if (row && Android.connectedOverNetwork(row)) {
            message = "Paired with " + row.name;
            stopFollowing();
        } else if (row && row.announced !== "" && row.announced !== pairedAddressTried && !busy) {
            pairedAddressTried = row.announced;
            const serial = row.serial;
            const name = row.name;
            devices.connectPaired(serial, row.announced, outcome => {
                if (outcome !== "connected" && pairedSerial === serial)
                    notConnected(name, outcome);
            });
        }
    }

    // The paired Android device didn't connect: say why instead of "Paired,
    // connecting…". It stays paired; Connect in the list tries again.
    function notConnected(name, outcome) {
        message = "";
        problem = Pairing.pairedButNotConnected(name, outcome);
        stopFollowing();
    }

    function stopFollowing() {
        paired = true;
        pairedSerial = "";
        connectWait.stop();
    }

    // What waits for adb to be free: pairing with the Android device that
    // scanned the QR code, and connecting the one just paired.
    function follow() {
        followPairedDevice();
        followQrCode();
    }

    onWatchingChanged: {
        connectWait.stop();
        if (!watching)
            return;
        paired = false;
        message = "";
        problem = "";
        pairedSerial = "";
        newQrCode();
    }

    // An Android device that announces itself while another action runs is
    // followed once that action is done.
    onBusyChanged: {
        if (!busy)
            Qt.callLater(follow);
    }

    property var deviceChanges: Connections {
        target: root.devices

        function onServicesChanged() {
            root.follow();
        }

        function onRowsChanged() {
            root.follow();
        }
    }

    // How long a paired Android device has to connect before pairing stops
    // waiting and says so.
    property var connectWait: Timer {
        id: connectWait

        interval: 20000
        onTriggered: {
            if (root.pairedSerial === "")
                return;
            // A connect is running for it; its outcome will tell.
            if (root.busy) {
                restart();
                return;
            }
            const row = root.devices.rowFor(root.pairedSerial);
            root.notConnected(row ? row.name : root.pairedSerial, "notAnnounced");
        }
    }

    property var pairProcess: Process {
        id: pairProcess

        property string password: ""

        stdout: StdioCollector {
            id: pairOutput
        }
        onExited: {
            const output = pairOutput.text;
            const password = pairProcess.password;
            Qt.callLater(() => root.pairDone(output, password));
        }
    }

    property var qrProcess: Process {
        id: qrProcess

        property string path: ""

        onExited: exitCode => {
            root.qrencodeAvailable = exitCode !== 127;
            root.qrImage = exitCode === 0 ? "file://" + path : "";
        }
    }
}
