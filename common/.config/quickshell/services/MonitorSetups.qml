import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick
import "MonitorChange.js" as MonitorChange
import "MonitorSetup.js" as MonitorSetup
import "MonitorToast.js" as MonitorToast
import "QuickSwitch.js" as QuickSwitch

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
    // What the quick switch offers, as QuickSwitch.choices gives it. Hand one to `quickSwitch`.
    readonly property var quickSwitchChoices: QuickSwitch.choices(internal.entries)
    // Whether every monitor is flashing its number, and that number.
    readonly property bool identifying: identifyTimer.running
    // Whether to hold the toasts: the shell's lock screen is up.
    property bool locked: false
    readonly property string unreadMessage: "The saved monitor setups can't be read, so nothing was changed."
    // Whether the toast for an unknown combination is up. `dismissToast` takes it down.
    readonly property bool offeringChoices: internal.toast.offering
    // What's being told about a failure, "" for nothing. `dismissNotice` takes it down.
    readonly property string notice: internal.toast.notice

    function numberOf(port) {
        return MonitorSetup.numberOf(internal.entries, port);
    }

    // A monitor's modes, as MonitorModes.parsedModes gives them.
    function modesOf(port) {
        return MonitorSetup.modesOf(internal.monitors, port);
    }

    // Tries out `entries`. False, with nothing changed, if they would leave every screen dark, are
    // what's already there, another step is still running, or the saved file can't be read.
    function apply(next) {
        if (!MonitorChange.canTry(next, internal.entries, internal.busy))
            return false;

        const text = fileText();
        if (text === undefined) {
            warn(unreadMessage);
            return false;
        }
        if (MonitorSetup.parsedFile(text) === null) {
            // Asking Hyprland to read it moves it aside as .bad, so the next try starts clean, and
            // that's what brings up the toast saying so.
            askHyprland();
            return false;
        }
        const current = internal.entries;
        internal.entries = next;
        carryOut(MonitorChange.changed(internal.change, text, current, next, Date.now()));
        return true;
    }

    // Tries out one of `quickSwitchChoices`, the way `apply` does. Mirror copies the focused monitor.
    // A choice is remembered even if the monitors are already like that, as Extend is for a new one.
    function quickSwitch(choice) {
        const focused = Hyprland.focusedMonitor ? Hyprland.focusedMonitor.name : "";
        const next = QuickSwitch.entriesFor(choice, internal.entries, focused, modesOf);
        return apply(next) || remember(next);
    }

    function remember(next) {
        if (!MonitorChange.canRemember(next, internal.entries, internal.busy, counting))
            return false;
        const text = fileText();
        const step = MonitorChange.remembered(text, next);
        if (text === undefined)
            warn(unreadMessage);
        if (step === null)
            return false;
        carryOut(step);
        return true;
    }

    function dismissToast() {
        internal.toast = MonitorToast.dismissed(internal.toast);
    }

    function dismissNotice() {
        internal.toast = MonitorToast.noticeDismissed(internal.toast);
    }

    // Whether a monitor is copying another, so has no bar.
    function isMirroring(port) {
        return QuickSwitch.mirroring(internal.entries, port);
    }

    function keep() {
        if (!counting || internal.busy)
            return;
        if (overtaken())
            warn("Hyprland had already gone back, so nothing was kept.");
        else
            carryOut(MonitorChange.kept(internal.change));
    }

    // Doesn't wait for Hyprland to answer, as that may be what's wrong.
    function revert() {
        if (!counting)
            return;
        if (internal.asking)
            stopAsking();
        else if (internal.busy)
            return;
        if (!overtaken())
            carryOut(MonitorChange.reverted(internal.change));
    }

    // Whether Hyprland went back by itself, which leaves nothing to answer. Ends the countdown if so.
    function overtaken() {
        if (!MonitorChange.overtaken(internal.change, fileText()))
            return false;
        internal.change = MonitorChange.idle;
        finished();
        return true;
    }

    // Removes a saved setup, by its `combination`, without touching the monitors: Hyprland only
    // notices the next time it detects them. False, with nothing changed, during a countdown or
    // another step, or if the file can't be read.
    function forget(combination) {
        if (internal.busy || counting)
            return false;
        const step = MonitorChange.forgotten(fileText(), combination);
        if (step === null) {
            warn(unreadMessage);
            return false;
        }
        carryOut(step);
        return true;
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

    // The saved file as it is now: its text, null if it isn't there, undefined if it couldn't be
    // loaded. Unless a signal says otherwise, it couldn't.
    function fileText() {
        internal.fileLoad = "failed";
        file.reload();
        file.waitForJob();
        return MonitorSetup.loadedText(internal.fileLoad, file.text());
    }

    function warn(message) {
        internal.toast = MonitorToast.withNotice(internal.toast, message);
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
        if (internal.askAfterWrite)
            askHyprland();
        else
            finished();
    }

    function askHyprland() {
        internal.asking = true;
        applier.running = true;
        applierTimeout.restart();
    }

    // Gives up on the hyprctl running. It may yet print something, which counts for nothing.
    function stopAsking() {
        internal.asking = false;
        internal.staleAnswers++;
        applierTimeout.stop();
        applier.running = false;
    }

    function hyprlandAnswered(output) {
        if (internal.staleAnswers > 0) {
            internal.staleAnswers--;
            return;
        }
        internal.asking = false;
        applierTimeout.stop();
        takeAnswer(output);
    }

    function takeAnswer(output) {
        const answer = MonitorChange.afterAnswer(internal.change, output);
        if (answer.warning !== "")
            warn(answer.warning);
        if (answer.step !== null)
            carryOut(answer.step);
        else
            finished();
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
        const saved = fileText();
        if (MonitorChange.overtaken(internal.change, saved))
            internal.change = MonitorChange.idle;
        const data = MonitorSetup.parsedFile(saved) || { setups: [] };
        const present = MonitorSetup.presentMonitors(reading.monitors, reading.lidClosed);
        internal.monitors = reading.monitors;
        internal.entries = MonitorSetup.entriesFrom(reading.monitors, MonitorSetup.savedEntries(data, present),
            reading.lidClosed);
        internal.savedSetups = MonitorSetup.listedSetups(data);
        internal.toast = MonitorToast.afterReading(internal.toast, MonitorSetup.combination(present),
            MonitorSetup.savedEntries(data, present).length > 0, root.locked);
        told.combination = internal.toast.combination;
        if (!root.locked)
            notices.running = true;
    }

    function tell(text) {
        const notice = MonitorToast.noticed(text, told.fallbacks);
        told.fallbacks = notice.told;
        if (notice.message !== "")
            warn(notice.message);
    }

    // What waited for the unlock is whatever the first reading after it finds.
    onLockedChanged: {
        if (!locked)
            refresh();
    }

    Component.onCompleted: {
        refresh();
        // A countdown the shell didn't live to finish is one nobody answered.
        const cutShort = MonitorChange.interrupted(fileText());
        if (cutShort !== null)
            carryOut(MonitorChange.reverted(cutShort));
    }

    // What the toasts have already said, so that a reload of the shell doesn't say it again.
    PersistentProperties {
        id: told

        reloadableId: "monitorSetups"

        property string combination: ""
        property string fallbacks: ""

        onLoaded: internal.toast = MonitorToast.restored(combination)
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
        property bool asking: false
        // Answers to come from a hyprctl that was given up on.
        property int staleAnswers: 0
        // How the last load of the saved file went: see MonitorSetup.loadedText.
        property string fileLoad: "failed"
        property bool readAgain: false
        property var toast: MonitorToast.idle
    }

    FileView {
        id: file

        path: (Quickshell.env("XDG_CONFIG_HOME") || Quickshell.env("HOME") + "/.config") + "/hypr/monitor-setups.json"
        blockLoading: true
        atomicWrites: true
        printErrors: false

        onLoaded: internal.fileLoad = "loaded"
        onLoadFailed: error => internal.fileLoad = error === FileViewError.FileNotFound ? "missing" : "failed"
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
        onExited: root.written()
    }

    Process {
        id: applier

        command: MonitorChange.applyCommand
        stdout: StdioCollector {
            onStreamFinished: root.hyprlandAnswered(text)
        }
    }

    // A hyprctl that hangs mustn't hold up everything after it.
    Timer {
        id: applierTimeout

        interval: 5000
        onTriggered: {
            root.stopAsking();
            root.takeAnswer("no answer from hyprctl");
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

    // What Hyprland left for the shell beside the saved file.
    Process {
        id: notices

        command: ["sh", Quickshell.shellDir + "/services/monitor-notices.sh", file.path]
        stdout: StdioCollector {
            onStreamFinished: root.tell(text)
        }
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
