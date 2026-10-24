import Quickshell.Io
import Quickshell.Services.Pipewire
import QtQuick
import "CavaOutput.js" as CavaOutput

// The one cava process the whole shell shares. It runs only while some bar
// draws the Cava bar element (see setDrawing) and listens to the default
// audio output, restarting when the default changes so it follows it.
QtObject {
    id: root

    // How many bars cava computes: the most any drawn Cava bar element asks
    // for (its `barCount`); each resamples the frame down to its own.
    readonly property int barCount: CavaOutput.sharedBarCount(drawers.map(drawer => drawer.barCount))
    // The latest frame, one height from 0 to 1 per bar; flat while cava
    // isn't running.
    property var heights: CavaOutput.flatHeights(barCount)
    // The Cava bar elements drawing right now.
    property var drawers: []
    readonly property bool wanted: drawers.length > 0
    property bool restarting: false

    // Called by each Cava bar element when it starts or stops being drawn.
    function setDrawing(drawer, drawing) {
        const others = drawers.filter(entry => entry !== drawer);
        drawers = drawing ? others.concat([drawer]) : others;
    }

    // A planned restart, so cava follows a new default output or bar count.
    function restart() {
        if (!cava.running)
            return;
        restarting = true;
        cava.running = false;
    }

    onWantedChanged: cava.running = wanted
    onBarCountChanged: restart()

    property var defaultOutputWatcher: Connections {
        target: Pipewire

        function onDefaultAudioSinkChanged() {
            root.restart();
        }
    }

    property var process: Process {
        id: cava

        // The config goes in through stdin, so nothing is written to disk.
        command: ["sh", "-c", "printf '%s' \"$1\" | exec cava -p /dev/stdin", "sh",
            CavaOutput.config(root.barCount)]

        stdout: SplitParser {
            onRead: data => root.heights = CavaOutput.frameHeights(data, root.barCount)
        }

        onExited: {
            root.heights = CavaOutput.flatHeights(root.barCount);
            if (root.restarting) {
                root.restarting = false;
                running = root.wanted;
            }
        }
    }
}
