import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import QtQuick
import "../components/bar/CapsuleRouting.js" as CapsuleRouting
import "../components/panels" as Panels
import "../components/panels/OsdChange.js" as OsdChange

// The on-screen display and the six changes it shows: IPC sends the volume
// and brightness keys, it watches Caps Lock itself, and the rest of the shell
// sends audio outputs, bar profiles and the keep-awake keybind. Each shows on
// the focused monitor only (CapsuleRouting.changeTarget): in its capsule if it has
// one, else in the OSD on that monitor.
Scope {
    id: root

    required property var appearance
    // The bar module (modules/Bar.qml), for the bars and the focused monitor.
    required property var bar

    readonly property var audio: Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.audio
        ? Pipewire.defaultAudioSink.audio : null
    // Caps Lock as last read, and whether it has been read once: the first
    // read is how it already was, not a change.
    property bool capsLocked: false
    property bool capsRead: false

    function showAudioOutput(output) {
        show(OsdChange.audioOutput(output));
    }

    function showBarProfile(name) {
        show(OsdChange.barProfile(name));
    }

    function showKeepAwake(on, duration) {
        show(OsdChange.keepAwake(on, duration));
    }

    // Shows `change` (see OsdChange.js) where CapsuleRouting.changeTarget says.
    function show(change) {
        const target = CapsuleRouting.changeTarget(root.bar.bars(), root.bar.focusedMonitor());
        if (target.capsule) {
            target.capsule.showChange(change);
        } else if (target.osd !== undefined) {
            osdPopup.screen = target.osd || (Quickshell.screens.values.length > 0 ? Quickshell.screens.values[0] : null);
            osdPopup.show(change);
        }
    }

    function readCaps(on) {
        if (root.capsRead && on !== root.capsLocked)
            show(OsdChange.capsLock(on));
        root.capsLocked = on;
        root.capsRead = true;
    }

    Panels.OsdPopup {
        id: osdPopup

        appearance: root.appearance
    }

    PwObjectTracker {
        objects: Pipewire.defaultAudioSink ? [Pipewire.defaultAudioSink] : []
    }

    Timer {
        interval: 500
        running: true
        repeat: true
        onTriggered: {
            if (!capsQuery.running)
                capsQuery.running = true;
        }
    }

    Process {
        id: capsQuery

        command: ["sh", "-c", "hyprctl devices -j | jq -r '[.. | objects | select(has(\"capsLock\")) | .capsLock] | any'"]
        stdout: SplitParser {
            onRead: data => root.readCaps(data.trim() === "true")
        }
    }

    Process {
        id: brightnessQuery

        command: ["sh", "-c", "brightnessctl -m | cut -d, -f4"]
        stdout: SplitParser {
            onRead: data => {
                const match = data.match(/(\d+(?:\.\d+)?)%/);

                if (match)
                    root.show(OsdChange.brightness(Number(match[1]) / 100));
            }
        }
    }

    IpcHandler {
        target: "osd"

        function volume() {
            root.show(OsdChange.volume(root.audio ? root.audio.volume : 0,
                !root.audio || root.audio.muted));
        }

        function brightness() {
            brightnessQuery.running = true;
        }
    }
}
