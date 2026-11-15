import QtQuick
import QtTest
import "../services/Printers.js" as Printers

// The printers in the Printers panel, read from what `lpstat -l -p -d -v`
// prints under LC_ALL=C (the lines below follow CUPS 2.4's lpstat), and
// the commands that set the default printer and remove one.
TestCase {
    name: "Printers"

    function test_noPrintersAddedListsNone() {
        compare(Printers.parse(""), []);
        compare(Printers.parse("no system default destination\n"), []);
    }

    readonly property string idleOnTheNetwork: [
        "printer Office_Laser is idle.  enabled since Sat 15 Nov 2026 10:02:11 AM CET",
        "\tDescription: HP LaserJet Pro M404",
        "\tAlerts: none",
        "system default destination: Office_Laser",
        "device for Office_Laser: ipp://laser.local:631/ipp/print",
        ""
    ].join("\n")

    function test_anIdlePrinterIsListedWithItsConnectionAndDefault() {
        compare(Printers.parse(idleOnTheNetwork), [{
            name: "Office_Laser",
            description: "HP LaserJet Pro M404",
            state: "idle",
            reason: "",
            connection: "network",
            isDefault: true
        }]);
    }

    function connectionOf(uri) {
        return Printers.parse("printer P is idle.  enabled since now\ndevice for P: " + uri + "\n")[0].connection;
    }

    // ipp-usb serves a USB printer as IPP on localhost, so that is USB too.
    function test_theDeviceUriTellsUsbFromNetwork() {
        for (const uri of ["usb://HP/LaserJet%20Pro%20M404?serial=PHB1234", "hp:/usb/HP_LaserJet?serial=X",
                "ipp://localhost:60000/ipp/print", "ipp://127.0.0.1:60001/ipp/print", "ipps://[::1]:60000/ipp/print"])
            compare(connectionOf(uri), "usb", uri);
        for (const uri of ["ipp://laser.local:631/ipp/print", "ipps://192.168.1.20/ipp/print",
                "dnssd://HP%20LaserJet._ipp._tcp.local/?uuid=1234", "socket://10.0.0.5:9100",
                "lpd://printer/queue", "implicitclass://Office_Laser/", "hp:/net/HP_LaserJet?ip=10.0.0.5"])
            compare(connectionOf(uri), "network", uri);
    }

    function stateOf(lines) {
        const printer = Printers.parse(lines.join("\n") + "\n")[0];
        return [printer.state, printer.reason];
    }

    function test_aPrinterPrintingAJobIsPrinting() {
        compare(stateOf(["printer Office_Laser now printing Office_Laser-42.  enabled since Sat 15 Nov 2026",
            "\tDescription: ", "\tAlerts: none"]), ["printing", ""]);
    }

    function test_aDisabledPrinterIsStoppedWithCupsReason() {
        compare(stateOf(["printer Office_Laser disabled since Sat 15 Nov 2026 -",
            "\tPaused by the administrator", "\tDescription: HP", "\tAlerts: paused"]),
            ["stopped", "Paused by the administrator"]);
        compare(stateOf(["printer Office_Laser disabled since Sat 15 Nov 2026 -", "\treason unknown",
            "\tDescription: HP", "\tAlerts: paused"]), ["stopped", ""]);
    }

    // CUPS keeps a printer that reports an error idle or printing; the
    // alerts say so.
    function test_anErrorAlertIsAnError() {
        compare(stateOf(["printer Office_Laser is idle.  enabled since Sat 15 Nov 2026",
            "\tThe printer is out of paper.", "\tDescription: HP",
            "\tAlerts: media-empty-error media-needed-report"]),
            ["error", "The printer is out of paper."]);
        compare(stateOf(["printer Office_Laser is idle.  enabled since Sat 15 Nov 2026",
            "\tDescription: HP", "\tAlerts: media-jam-error"]), ["error", "Media jam"]);
    }

    // A message on a printer that's fine is no reason for anything.
    function test_aWorkingPrinterHasNoReason() {
        compare(stateOf(["printer Office_Laser is idle.  enabled since Sat 15 Nov 2026",
            "\tReady to print.", "\tDescription: HP", "\tAlerts: none"]), ["idle", ""]);
        compare(stateOf(["printer Office_Laser now printing Office_Laser-7.  enabled since Sat 15 Nov 2026",
            "\tPrinting page 2, 50% complete.", "\tDescription: HP", "\tAlerts: none"]), ["printing", ""]);
    }

    function test_whatThePanelSaysOfAPrinter() {
        compare(Printers.statusText({ state: "idle", reason: "" }), "Idle");
        compare(Printers.statusText({ state: "printing", reason: "" }), "Printing");
        compare(Printers.statusText({ state: "stopped", reason: "" }), "Stopped");
        compare(Printers.statusText({ state: "stopped", reason: "Paused" }), "Stopped: Paused");
        compare(Printers.statusText({ state: "error", reason: "Media jam" }), "Error: Media jam");
        compare(Printers.connectionText("network"), "Network");
        compare(Printers.connectionText("usb"), "USB");
        compare(Printers.connectionText("local"), "Local");
    }

    // Under LC_ALL=C, which is what parse() reads; wheel lets lpadmin run
    // without a password.
    function test_theCommandsThatReadAndChangePrinters() {
        compare(Printers.listCommand, ["env", "LC_ALL=C", "lpstat", "-l", "-p", "-d", "-v"]);
        compare(Printers.setDefaultCommand("Office_Laser"), ["lpadmin", "-d", "Office_Laser"]);
        compare(Printers.removeCommand("Office_Laser"), ["lpadmin", "-x", "Office_Laser"]);
    }

    // lpstat complains when there are no printers, which isn't a problem.
    function test_onlyARealComplaintFromLpstatIsAProblem() {
        compare(Printers.listProblem("lpstat: No destinations added.\nlpstat: No destinations added.\n"), "");
        compare(Printers.listProblem(""), "");
        compare(Printers.listProblem("lpstat: Scheduler is not running.\n"), "Scheduler is not running.");
    }

    function test_warningsAndReportsAreNoError() {
        compare(stateOf(["printer Office_Laser is idle.  enabled since Sat 15 Nov 2026",
            "\tDescription: HP", "\tAlerts: toner-low-warning cups-waiting-for-job-completed"]),
            ["idle", ""]);
    }

    function test_aPrinterHoldingNewJobsIsIdle() {
        compare(stateOf(["printer Office_Laser is holding new jobs.  enabled since Sat 15 Nov 2026",
            "\tDescription: HP", "\tAlerts: hold-new-jobs"]), ["idle", ""]);
    }

    function test_everyPrinterIsListedByName() {
        const printers = Printers.parse([
            "printer Zebra_Label is idle.  enabled since Sat 15 Nov 2026",
            "\tDescription: Zebra", "\tAlerts: none",
            "printer Brother now printing Brother-3.  enabled since Sat 15 Nov 2026",
            "\tDescription: Brother HL", "\tAlerts: none",
            "no system default destination",
            "device for Zebra_Label: usb://Zebra/LP2844",
            "device for Brother: ipp://brother.local/ipp/print",
            ""].join("\n"));
        compare(printers.map(printer => [printer.name, printer.state, printer.connection, printer.isDefault]), [
            ["Brother", "printing", "network", false],
            ["Zebra_Label", "idle", "usb", false]
        ]);
    }

    // A printer that's neither, like a PDF printer.
    function test_aPrinterOnNoWireIsLocal() {
        compare(connectionOf("cups-pdf:/"), "local");
        compare(connectionOf("file:///dev/null"), "local");
    }
}
