import QtQuick
import QtTest
import "../components/panels/PrinterLabels.js" as Labels

// What the Printers panel's sections say of a printer, a print job and how
// a printer or scanner is connected.
TestCase {
    name: "PrinterLabels"

    function test_whatThePanelSaysOfAPrinter() {
        compare(Labels.statusText({ state: "idle", reason: "" }), "Idle");
        compare(Labels.statusText({ state: "printing", reason: "" }), "Printing");
        compare(Labels.statusText({ state: "stopped", reason: "" }), "Stopped");
        compare(Labels.statusText({ state: "stopped", reason: "Paused" }), "Stopped: Paused");
        compare(Labels.statusText({ state: "error", reason: "Media jam" }), "Error: Media jam");
    }

    function test_howItsConnected() {
        compare(Labels.connectionText("network"), "Network");
        compare(Labels.connectionText("usb"), "USB");
        compare(Labels.connectionText("local"), "Local");
    }

    function test_whatThePanelSaysOfAPrintJob() {
        compare(Labels.jobText({ state: "held", owner: "ana", progress: "" }), "Held · ana");
        compare(Labels.jobText({ state: "printing", owner: "ndrolp", progress: "Page 2 of 5" }),
            "Printing · Page 2 of 5 · ndrolp");
        compare(Labels.jobText({ state: "waiting", owner: "", progress: "" }), "Waiting");
        compare(Labels.jobText({ state: "stopped", owner: "ana", progress: "" }), "Stopped · ana");
    }
}
