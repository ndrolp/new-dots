import Quickshell
import Quickshell.Io
import QtQuick
import "PrinterDiscovery.js" as Discovery

// The discovered printers, for the Printers panel: IPP printers avahi sees
// on the network and USB ones ipp-usb serves, without the ones already
// added. avahi-browse streams them only while `watching` (the panel is
// open) and is stopped when it closes; nothing runs while it's closed.
// What it prints is parsed in PrinterDiscovery.js. *Add* goes through
// lpadmin, which needs no password for a user in wheel.
Scope {
    id: root

    property bool watching: false
    // The printers added, from the printers service; when they change the
    // device URIs are read again, so an added printer leaves this list.
    property var printers: []

    // [{ key, model, service, connection, uri, driverless }], by model.
    readonly property var discovered: Discovery.discovered(services, addedUris)
    // Why printers can't be found ("" otherwise).
    property string problem: ""
    // The printer being added (its key), and why the last add failed.
    property string adding: ""
    property string addFailureKey: ""
    property string addFailure: ""

    // avahi-browse's resolved services, kept by takeLine().
    property var services: ({})
    property var addedUris: []

    signal added()

    function add(printer) {
        if (addProcess.running)
            return;
        adding = printer.key;
        addFailureKey = "";
        addFailure = "";
        addProcess.model = printer.model;
        addProcess.command = Discovery.addCommand(printer, printers.map(added => added.name));
        addProcess.running = true;
    }

    // For a printer that can't print driverless: CUPS's own setup, with drivers.
    function openPrintSettings() {
        Quickshell.execDetached(["system-config-printer"]);
    }

    function start() {
        problem = "";
        for (const browser of browsers)
            browser.running = true;
        readAdded();
    }

    function readAdded() {
        if (!addedProcess.running)
            addedProcess.running = true;
    }

    onWatchingChanged: {
        if (watching) {
            addFailureKey = "";
            addFailure = "";
            start();
        } else {
            for (const browser of browsers)
                browser.running = false;
            services = {};
        }
    }

    onPrintersChanged: {
        if (watching)
            readAdded();
    }

    component Browser: Process {
        id: browser

        required property string type

        command: Discovery.browseCommand(type)
        stdout: SplitParser {
            onRead: line => root.services = Discovery.takeLine(root.services, line)
        }
        stderr: StdioCollector {
            id: browseErrors
        }
        onExited: exitCode => {
            if (!root.watching)
                return;
            root.problem = Discovery.browseProblem(browseErrors.text)
                || (exitCode !== 0 ? "Can't look for printers: avahi-browse stopped" : "");
        }
    }

    readonly property var browsers: [ippBrowser, ippsBrowser]

    Browser {
        id: ippBrowser

        type: "_ipp._tcp"
    }

    Browser {
        id: ippsBrowser

        type: "_ipps._tcp"
    }

    // avahi-daemon may be started while the panel is open: look again.
    Timer {
        interval: 5000
        repeat: true
        running: root.watching && root.problem !== ""
        onTriggered: root.start()
    }

    Process {
        id: addedProcess

        command: Discovery.addedCommand
        stdout: StdioCollector {
            onStreamFinished: root.addedUris = Discovery.addedUris(text)
        }
    }

    Process {
        id: addProcess

        property string model: ""

        stderr: StdioCollector {
            id: addErrors
        }
        onExited: exitCode => {
            if (exitCode !== 0) {
                root.addFailureKey = root.adding;
                root.addFailure = Discovery.addProblem(addErrors.text, model);
            }
            root.adding = "";
            // The printers are read again only while the panel is open.
            if (root.watching)
                root.added();
        }
    }
}
