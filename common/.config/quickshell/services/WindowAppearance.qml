import Quickshell
import Quickshell.Io
import QtQuick
import "WindowAppearance.js" as WindowAppearance

// How Hyprland draws windows: the Windows section's settings. Each `set` saves
// ~/.config/hypr/window-appearance.json atomically, then asks Hyprland to run
// only its window-appearance module again (`hyprctl eval`, never a full
// reload). While a slider is dragged that happens at most every `throttle` ms,
// with the last value always written. Hyprland owns the file and reads it when
// it loads (hypr/modules/appearence/windows.lua); what each setting takes and
// the text written are in WindowAppearance.js.
Scope {
    id: root

    // Every setting's value, by its key in the file (WindowAppearance.settings).
    readonly property var values: internal.values
    readonly property int throttle: 100
    // Whether Hyprland couldn't take the last apply (the shell runs outside
    // it, or the module failed). What was set is saved all the same, and
    // Hyprland reads it when it next starts; the next apply that works
    // clears it.
    readonly property bool applyFailed: internal.applyFailed

    // Sets `key` to `value`, kept in its range, and saves and applies it soon.
    function set(key, value) {
        internal.values = WindowAppearance.withValue(internal.values, key, value);
        internal.unsaved = true;
        if (!throttleTimer.running)
            throttleTimer.start();
    }

    function save() {
        if (!internal.unsaved)
            return;
        internal.unsaved = false;
        file.setText(WindowAppearance.fileText(internal.values));
    }

    // Every setting back to its default, applied straight away. It removes the
    // saved file rather than writing the defaults into it, so a later change to
    // a default in the repo still reaches this machine. A change not yet
    // written is dropped.
    function reset() {
        throttleTimer.stop();
        internal.unsaved = false;
        internal.values = WindowAppearance.defaults();
        remover.running = true;
    }

    function apply() {
        if (applier.running)
            internal.applyAgain = true;
        else
            applier.running = true;
    }

    QtObject {
        id: internal

        property var values: WindowAppearance.defaults()
        property bool unsaved: false
        property bool applyAgain: false
        property bool applyFailed: false
    }

    FileView {
        id: file

        path: (Quickshell.env("XDG_CONFIG_HOME") || Quickshell.env("HOME") + "/.config") + "/hypr/window-appearance.json"
        atomicWrites: true
        printErrors: false
        // Hyprland reads it on its own; the shell only reads it once, to show it.
        watchChanges: false

        onLoaded: internal.values = WindowAppearance.valuesFrom(text())
        onLoadFailed: internal.values = WindowAppearance.defaults()
        onSaved: root.apply()
    }

    // Fires while changes keep coming, so a drag applies as it goes.
    Timer {
        id: throttleTimer

        interval: root.throttle
        onTriggered: root.save()
    }

    Process {
        id: remover

        command: ["rm", "-f", file.path]
        onExited: root.apply()
    }

    Process {
        id: applier

        command: WindowAppearance.applyCommand
        stdout: StdioCollector {
            id: applierOutput
        }
        onExited: exitCode => {
            internal.applyFailed = WindowAppearance.applyFailed(exitCode, applierOutput.text);
            if (internal.applyAgain) {
                internal.applyAgain = false;
                applier.running = true;
            }
        }
    }
}
