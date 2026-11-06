import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick
import "MonitorChange.js" as MonitorChange
import "MonitorSetup.js" as MonitorSetup
import "MonitorModes.js" as MonitorModes

// The shell's one way to change the monitors: Displays and the quick switch both hand `apply` the
// entries they want. It writes the saved file, asks Hyprland to apply it and runs the Keep or Revert
// countdown; only Keep saves. What each step does is decided in MonitorChange.js and MonitorSetup.js;
// this only carries it out. Hyprland owns the setups (docs/adr/0002-hyprland-owns-monitor-setups.md).
Scope {
    id: root

    // The setup the monitors are in now, and any change being tried out, as entries
    // (MonitorSetup.js). A closed lid's laptop screen isn't one of them.
    readonly property var entries: internal.entries
    // Whether a change is waiting for Keep or Revert, and the whole seconds left.
    readonly property bool counting: MonitorChange.counting(internal.change)
    readonly property int secondsLeft: internal.secondsLeft
    // Each saved setup as { combination, name, monitors }.
    readonly property var savedSetups: internal.savedSetups
    // Whether every monitor is flashing its number, and that number.
    readonly property bool identifying: identifyTimer.running

    function numberOf(port) {
        return internal.entries.findIndex(entry => entry.port === port) + 1;
    }

    // A monitor's modes, as MonitorModes.parsedModes gives them.
    function modesOf(port) {
        return MonitorSetup.modesOf(internal.monitors, port);
    }

    // Tries out `entries`. False, with nothing changed, if they would leave every screen dark, are
    // what's already there, or another step is still running.
    function apply(next) {
        if (internal.busy || next.length === 0 || !MonitorSetup.showsSomething(next)
            || MonitorSetup.sameEntries(next, internal.entries))
            return false;

        const text = fileText();
        if (MonitorSetup.parsedFile(text) === null) {
            // Asking Hyprland to read it moves it aside as .bad, so the next try starts clean.
            warn("The saved monitor setups can't be read, so they were set aside. Try again.");
            askHyprland();
            return false;
        }
        const current = internal.entries;
        internal.entries = next;
        carryOut(MonitorChange.changed(internal.change, text, current, next, Date.now()));
        return true;
    }

    function keep() {
        if (counting && !internal.busy)
            carryOut(MonitorChange.kept(internal.change));
    }

    function revert() {
        if (counting && !internal.busy)
            carryOut(MonitorChange.reverted(internal.change));
    }

    function identify() {
        identifyTimer.restart();
    }

    // Reads the monitors and the lid again.
    function refresh() {
        if (reader.running)
            internal.readAgain = true;
        else
            reader.running = true;
    }

    function fileText() {
        file.reload();
        file.waitForJob();
        const text = file.text();
        return internal.fileMissing || text === "" ? null : text;
    }

    function warn(message) {
        warning.exec(["notify-send", "-u", "critical", "Displays", message]);
    }

    // One step from MonitorChange.js: writes or removes the file, then asks Hyprland if it says to.
    function carryOut(step) {
        internal.busy = true;
        internal.change = step.state;
        internal.secondsLeft = MonitorChange.secondsLeft(step.state, Date.now());
        internal.askAfterWrite = step.apply;
        if (step.remove)
            remover.running = true;
        else
            file.setText(step.text);
    }

    function written() {
        internal.fileMissing = false;
        if (internal.askAfterWrite)
            askHyprland();
        else
            finished();
    }

    function askHyprland() {
        applier.running = true;
    }

    function hyprlandAnswered(output) {
        if (!MonitorChange.answeredOk(output)) {
            warn("Hyprland didn't apply the monitor setup: " + output.trim());
            if (counting || MonitorChange.restoring(internal.change))
                carryOut(MonitorChange.restored(internal.change));
            else
                finished();
        } else if (MonitorChange.restoring(internal.change)) {
            carryOut(MonitorChange.restored(internal.change));
        } else {
            finished();
        }
    }

    function finished() {
        internal.busy = false;
        settle.restart();
    }

    function takeReading(text) {
        // Mid-step the file is being written and `entries` is ahead of the monitors. `finished` reads again.
        if (internal.busy)
            return;
        const reading = MonitorSetup.parsedReading(text);
        if (reading === null)
            return;
        const data = MonitorSetup.parsedFile(fileText()) || { setups: [] };
        const present = MonitorSetup.presentMonitors(reading.monitors, reading.lidClosed);
        internal.monitors = reading.monitors;
        internal.entries = MonitorSetup.entriesFrom(reading.monitors, MonitorSetup.savedEntries(data, present),
            reading.lidClosed);
        internal.savedSetups = MonitorSetup.listedSetups(data);
    }

    Component.onCompleted: {
        refresh();
        // A countdown the shell didn't live to finish is one nobody answered.
        const cutShort = MonitorChange.interrupted(fileText());
        if (cutShort !== null)
            carryOut(MonitorChange.reverted(cutShort));
    }

    QtObject {
        id: internal

        property var monitors: []
        property var entries: []
        property var savedSetups: []
        property var change: MonitorChange.idle
        property int secondsLeft: 0
        property bool busy: false
        property bool askAfterWrite: false
        property bool fileMissing: false
        property bool readAgain: false
    }

    FileView {
        id: file

        path: (Quickshell.env("XDG_CONFIG_HOME") || Quickshell.env("HOME") + "/.config") + "/hypr/monitor-setups.json"
        blockLoading: true
        atomicWrites: true
        printErrors: false

        onLoaded: internal.fileMissing = false
        onLoadFailed: error => internal.fileMissing = error === FileViewError.FileNotFound
        onSaved: root.written()
        onSaveFailed: error => {
            root.warn("The monitor setups couldn't be saved: " + FileViewError.toString(error));
            internal.change = MonitorChange.idle;
            root.finished();
        }
    }

    Process {
        id: remover

        command: ["rm", "-f", file.path]
        onExited: {
            internal.fileMissing = true;
            root.written();
        }
    }

    Process {
        id: applier

        command: MonitorChange.applyCommand
        stdout: StdioCollector {
            onStreamFinished: root.hyprlandAnswered(text)
        }
    }

    Process {
        id: reader

        command: ["sh", "-c", "cat /proc/acpi/button/lid/*/state 2>/dev/null; hyprctl monitors all -j"]
        stdout: StdioCollector {
            onStreamFinished: root.takeReading(text)
        }
        onExited: {
            if (internal.readAgain) {
                internal.readAgain = false;
                reader.running = true;
            }
        }
    }

    Process {
        id: warning
    }

    Connections {
        target: Hyprland

        function onRawEvent(event) {
            if (MonitorSetup.changesMonitors(event.name))
                settle.restart();
        }
    }

    // Hyprland changes monitors a moment after it's asked, and a change comes as several events.
    Timer {
        id: settle

        interval: 300
        onTriggered: root.refresh()
    }

    // Counts down from the clock, so a late tick doesn't stretch it.
    Timer {
        interval: 250
        repeat: true
        running: root.counting
        onTriggered: {
            internal.secondsLeft = MonitorChange.secondsLeft(internal.change, Date.now());
            if (MonitorChange.expired(internal.change, Date.now()))
                root.revert();
        }
    }

    Timer {
        id: identifyTimer

        interval: 2500
    }
}
