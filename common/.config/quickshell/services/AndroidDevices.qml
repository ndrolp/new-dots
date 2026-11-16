import Quickshell
import Quickshell.Io
import QtQuick
import "Assign.js" as Assign
import "AndroidDevices.js" as Android

// The Android devices and known devices, for the Android devices panel, and
// connecting and disconnecting them over the network with whatever adb is
// on PATH. It reads `adb devices -l` and `adb mdns services` every 2 s only
// while `watching` (the panel is open); nothing runs while it is closed.
// The rules are in AndroidDevices.js; this only runs adb. Pairing is
// AndroidPairing.qml, which reads `services` and connects through
// connectPaired. Known devices are kept in config/android-devices.json,
// which belongs to the machine and isn't tracked. Nothing connects on its own.
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
    // The action running ("connect", "disconnect", "wireless" or "") and the
    // serial of the row it is for.
    property string task: ""
    property string taskSerial: ""
    readonly property bool busy: task !== ""

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
                placeSerial(address, serial);
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

    // Connects an Android device pairing just paired at `address`, then
    // `done(outcome)` (connectOutcome / worstOutcome). The pairing service
    // reports what happened, so the device list says nothing. False when
    // another action is running.
    function connectPaired(serial, address, done) {
        if (!begin("connect", serial))
            return false;
        tryAddresses([address], [], outcome => {
            finish();
            done(outcome);
        });
        return true;
    }

    // Records that the network transport `transport` is the Android device
    // with hardware serial `serial`.
    function placeSerial(transport, serial) {
        const placed = Object.assign({}, serials);
        placed[transport] = serial;
        serials = placed;
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
        adbCheck.running = true;
    }

    // Every device connected over the network is remembered.
    onRowsChanged: Assign.ifChanged(knownDevices, "devices", Android.remembered(known, rows))
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
            if (exitCode === 0 && serial !== "")
                root.placeSerial(transport, serial);
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
