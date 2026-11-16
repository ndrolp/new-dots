import Quickshell
import Quickshell.Io
import QtQuick
import "Assign.js" as Assign
import "AndroidDevices.js" as Android

// The Android devices and known devices, for the Android devices panel, and
// pairing, connecting and disconnecting them over the network with whatever
// adb is on PATH. It reads `adb devices -l` and `adb mdns services` every
// 2 s only while `watching` (the panel is open); nothing runs while it is
// closed. The rules are in AndroidDevices.js; this only runs adb.
// Known devices are kept in config/android-devices.json, which belongs to
// the machine and isn't tracked. Nothing connects on its own.
QtObject {
    id: root

    property bool watching: false
    // Whether adb is on PATH (checked on every open); without it nothing runs.
    property bool adbAvailable: true
    readonly property string adbProblem: adbAvailable ? "" : Android.missingAdb

    // What adb reads now (AndroidDevices.js parseDevices / parseServices), and
    // the hardware serial each ip:port connection reported.
    property var devices: []
    property var services: []
    property var serials: ({})
    // The transports already asked for their serial.
    property var asked: ({})
    readonly property var known: knownDevices.devices
    // One row per Android device (AndroidDevices.js rows).
    readonly property var rows: Android.rows(devices, services, known, serials)

    // What the last action on a row did ("You can unplug it now") or why it
    // failed; "" otherwise.
    property string message: ""
    property string problem: ""
    // The action running ("connect", "disconnect", "wireless", "pair" or "")
    // and the serial of the row it is for.
    property string task: ""
    property string taskSerial: ""
    readonly property bool busy: task !== ""

    // Pairing: the QR code's service name and password (fresh on every
    // open), the drawn code ("" until drawn), and what pairing did.
    property var qr: ({ name: "", password: "" })
    property string qrImage: ""
    property bool qrencodeAvailable: true
    readonly property string qrProblem: qrencodeAvailable ? "" : Android.missingQrencode
    // True once a phone paired; the QR code is hidden until the next open.
    property bool paired: false
    property string pairMessage: ""
    property string pairProblem: ""
    // The phone just paired, waiting to be connected ("" for none), and the
    // address already tried for it.
    property string pairedSerial: ""
    property string pairedAddressTried: ""
    // What a phone showing its pairing code dialog announces ("" otherwise).
    readonly property string codeAddress: Android.codePairingAddress(services)

    // Nothing is read while the panel is closed.
    function refresh() {
        if (!watching || !adbAvailable)
            return;
        if (!devicesProcess.running)
            devicesProcess.running = true;
        if (!servicesProcess.running)
            servicesProcess.running = true;
    }

    function rowFor(serial) {
        return rows.find(row => row.serial === serial) || null;
    }

    // Runs `command` with its output merged, then `done(output, exitCode)`.
    function run(command, done) {
        stepProcess.done = done;
        stepProcess.command = Android.merged(command);
        stepProcess.running = true;
    }

    function begin(task, serial) {
        if (busy)
            return false;
        root.task = task;
        taskSerial = serial;
        message = "";
        problem = "";
        return true;
    }

    function finish() {
        task = "";
        taskSerial = "";
        refresh();
    }

    // Connect: the address mDNS announces now, then the last one remembered.
    function connect(row) {
        const addresses = Android.connectAddresses(row, known);
        if (!begin("connect", row.serial))
            return;
        tryAddresses(addresses, [], outcome => {
            if (outcome !== "connected")
                problem = Android.connectProblem(outcome);
            finish();
        });
    }

    // Tries `addresses` in turn until one connects, then `done(outcome)`: the
    // worst of the failures when none did.
    function tryAddresses(addresses, outcomes, done) {
        if (addresses.length === 0) {
            done(Android.worstOutcome(outcomes));
            return;
        }
        run(Android.connectCommand(addresses[0]), output => {
            const outcome = Android.connectOutcome(output);
            if (outcome === "connected")
                done(outcome);
            else
                tryAddresses(addresses.slice(1), outcomes.concat([outcome]), done);
        });
    }

    function disconnect(row) {
        if (!begin("disconnect", row.serial))
            return;
        run(Android.disconnectCommand(row.wifi), () => finish());
    }

    // Removes it from the list only: the phone keeps the pairing.
    function forget(row) {
        knownDevices.devices = Android.forgotten(known, row.serial);
    }

    // From USB: reads the phone's Wi-Fi address, has adbd listen on the
    // network, then connects to it there.
    function connectWirelessly(row) {
        if (!begin("wireless", row.serial))
            return;
        const serial = row.serial;
        run(Android.wifiIpCommand(serial), output => {
            const ip = Android.wifiIp(output);
            if (ip === "") {
                problem = "The phone isn't on Wi-Fi";
                finish();
                return;
            }
            run(Android.tcpipCommand(serial), () => {
                // adbd restarts to listen on the network; give it a moment.
                connectRetry.address = ip + ":" + Android.tcpipPort;
                connectRetry.serial = serial;
                connectRetry.left = 5;
                connectRetry.start();
            });
        });
    }

    function retryWirelessConnect() {
        const address = connectRetry.address;
        const serial = connectRetry.serial;
        run(Android.connectCommand(address), output => {
            if (Android.connectOutcome(output) === "connected") {
                const placed = Object.assign({}, serials);
                placed[address] = serial;
                serials = placed;
                message = "You can unplug it now";
                finish();
            } else if (--connectRetry.left > 0) {
                connectRetry.start();
            } else {
                problem = "Couldn't connect to " + address + ". Is the phone on this network?";
                finish();
            }
        });
    }

    // Pairs with the pairing service at `address`, then connects the phone
    // once it announces itself.
    function pair(address, password) {
        if (!begin("pair", ""))
            return;
        pairMessage = "";
        pairProblem = "";
        run(Android.pairCommand(address.trim(), password.trim()), output => {
            const serial = Android.pairedSerial(output);
            if (serial === "") {
                pairProblem = Android.pairProblem(output);
                // A QR code is only good for one try.
                if (password === qr.password)
                    newQrCode();
            } else {
                pairedSerial = serial;
                pairedAddressTried = "";
                pairMessage = "Paired, connecting…";
            }
            finish();
        });
    }

    function pairWithCode(address, code) {
        if (Android.canPairWithCode(address, code))
            pair(address, code);
    }

    function newQrCode() {
        const dir = Quickshell.env("XDG_RUNTIME_DIR") || "/tmp";
        qr = Android.qrPairing(Math.random);
        qrImage = "";
        qrProcess.path = Android.qrPath(dir, qr.name);
        qrProcess.command = Android.qrCommand(dir, qrProcess.path, Android.qrPayload(qr));
        qrProcess.running = true;
    }

    // The phone that scanned the QR code announces its name: pair with it.
    function followQrCode() {
        if (paired || busy || qr.name === "")
            return;
        const address = Android.pairingAddress(services, qr.name);
        if (address !== "")
            pair(address, qr.password);
    }

    // The phone just paired is connected once it announces itself (unless adb
    // already connected it); then pairing says which phone it was.
    function followPairedDevice() {
        if (pairedSerial === "")
            return;
        const row = rowFor(pairedSerial);
        if (row && (row.state === "wifi" || row.state === "both")) {
            pairMessage = "Paired with " + row.name;
            paired = true;
            pairedSerial = "";
        } else if (row && row.announced !== "" && row.announced !== pairedAddressTried && !busy) {
            pairedAddressTried = row.announced;
            begin("connect", row.serial);
            tryAddresses([row.announced], [], () => finish());
        }
    }

    // Asks one unplaced ip:port connection at a time for its serial.
    function placeTransports() {
        if (serialProcess.running)
            return;
        const transport = Android.unplacedTransports(devices, known, serials)
            .find(candidate => !asked[candidate]);
        if (!transport)
            return;
        const marked = Object.assign({}, asked);
        marked[transport] = true;
        asked = marked;
        serialProcess.transport = transport;
        serialProcess.command = Android.serialCommand(transport);
        serialProcess.running = true;
    }

    onWatchingChanged: {
        if (!watching)
            return;
        message = "";
        problem = "";
        paired = false;
        pairMessage = "";
        pairProblem = "";
        pairedSerial = "";
        newQrCode();
        adbCheck.running = true;
    }

    onRowsChanged: {
        // Every device connected over the network is remembered.
        Assign.ifChanged(knownDevices, "devices", Android.remembered(known, rows));
        followPairedDevice();
    }

    onServicesChanged: followQrCode()
    onDevicesChanged: placeTransports()

    property var poll: Timer {
        interval: 2000
        repeat: true
        running: root.watching && root.adbAvailable
        onTriggered: root.refresh()
    }

    property var connectRetry: Timer {
        id: connectRetry

        property string address: ""
        property string serial: ""
        property int left: 0

        interval: 1500
        onTriggered: root.retryWirelessConnect()
    }

    property var adbCheck: Process {
        id: adbCheck

        command: Android.toolCheck("adb")
        onExited: exitCode => {
            root.adbAvailable = exitCode === 0;
            root.refresh();
        }
    }

    property var devicesProcess: Process {
        id: devicesProcess

        command: Android.devicesCommand
        stdout: StdioCollector {
            // Only a change replaces the list, so the rows aren't rebuilt on every poll.
            onStreamFinished: Assign.ifChanged(root, "devices", Android.parseDevices(text))
        }
    }

    property var servicesProcess: Process {
        id: servicesProcess

        command: Android.servicesCommand
        stdout: StdioCollector {
            onStreamFinished: Assign.ifChanged(root, "services", Android.parseServices(text))
        }
    }

    property var serialProcess: Process {
        id: serialProcess

        property string transport: ""

        stdout: StdioCollector {
            id: serialOutput
        }
        onExited: exitCode => {
            const serial = serialOutput.text.trim();
            if (exitCode === 0 && serial !== "") {
                const placed = Object.assign({}, root.serials);
                placed[transport] = serial;
                root.serials = placed;
            }
            root.placeTransports();
        }
    }

    property var stepProcess: Process {
        id: stepProcess

        property var done: null

        stdout: StdioCollector {
            id: stepOutput
        }
        // The next step starts once this one has settled.
        onExited: exitCode => {
            const done = stepProcess.done;
            stepProcess.done = null;
            const output = stepOutput.text;
            if (done)
                Qt.callLater(() => done(output, exitCode));
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

    property var knownFile: FileView {
        path: Qt.resolvedUrl("../config/android-devices.json")
        atomicWrites: true
        watchChanges: true

        onFileChanged: reload()
        onAdapterUpdated: writeAdapter()

        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound)
                writeAdapter();
        }

        // [{ serial, model, address }]
        adapter: JsonAdapter {
            id: knownDevices

            property var devices: []
        }
    }
}
