import Quickshell.Io
import QtQuick
import "Assign.js" as Assign
import "Printers.js" as Printers

// The printers CUPS has added, for the Printers panel. It reads them only
// while `watching` (the panel is open), every few seconds so the list keeps
// up, and nothing runs while the panel is closed. lpstat's output is
// parsed in Printers.js; changes go through lpadmin, which needs no
// password for a user in wheel. The print jobs of one printer, the open
// one (`jobsPrinter`), are read along with the list.
QtObject {
    id: root

    property bool watching: false
    // [{ name, description, state, reason, connection, isDefault }], by name.
    property var printers: []
    // Why the printers couldn't be read, or the last change failed ("" otherwise).
    readonly property string failure: changeFailure || readFailure
    property string readFailure: ""
    property string changeFailure: ""
    readonly property bool changing: changeProcess.running
    // The printer whose print jobs are read ("" for none), and its jobs:
    // [{ id, document, owner, state, progress }].
    property string jobsPrinter: ""
    property var jobs: []

    function refresh() {
        if (!listProcess.running)
            listProcess.running = true;
        if (jobsPrinter !== "" && !jobsProcess.running) {
            jobsProcess.printer = jobsPrinter;
            jobsProcess.command = Printers.jobsCommand(jobsPrinter);
            jobsProcess.running = true;
        }
    }

    function cancelJob(id) {
        change(Printers.cancelJobCommand(id), "Couldn't cancel the print job");
    }

    function printTestPage(name) {
        change(Printers.testPageCommand(name), "Couldn't print a test page on " + name);
    }

    function setDefault(name) {
        change(Printers.setDefaultCommand(name), "Couldn't make " + name + " the default printer");
    }

    function remove(name) {
        change(Printers.removeCommand(name), "Couldn't remove " + name);
    }

    function change(command, fallback) {
        if (changeProcess.running)
            return;
        changeFailure = "";
        changeProcess.fallback = fallback;
        changeProcess.command = command;
        changeProcess.running = true;
    }

    onWatchingChanged: {
        if (watching) {
            changeFailure = "";
            refresh();
        }
    }

    onJobsPrinterChanged: {
        jobs = [];
        if (watching)
            refresh();
    }

    property var poll: Timer {
        interval: 3000
        repeat: true
        running: root.watching
        onTriggered: root.refresh()
    }

    property var listProcess: Process {
        id: listProcess

        command: Printers.listCommand
        stdout: StdioCollector {
            // Only a change replaces the list, so the panel's rows aren't
            // rebuilt on every poll.
            onStreamFinished: Assign.ifChanged(root, "printers", Printers.parse(text))
        }
        stderr: StdioCollector {
            onStreamFinished: root.readFailure = Printers.listProblem(text)
        }
    }

    property var jobsProcess: Process {
        id: jobsProcess

        // The printer these jobs are of; a reply for one no longer open is dropped.
        property string printer: ""

        stdout: StdioCollector {
            onStreamFinished: {
                if (jobsProcess.printer !== root.jobsPrinter)
                    return;
                Assign.ifChanged(root, "jobs", Printers.parseJobs(text));
            }
        }
        // Another printer was opened while this one was read.
        onExited: {
            if (printer !== root.jobsPrinter && root.watching)
                root.refresh();
        }
    }

    property var changeProcess: Process {
        id: changeProcess

        property string fallback: ""

        stderr: StdioCollector {
            id: changeErrors
        }
        onExited: exitCode => {
            if (exitCode !== 0)
                root.changeFailure = changeErrors.text.trim() || fallback;
            // Nothing is read once the panel has closed.
            if (root.watching)
                root.refresh();
        }
    }
}
