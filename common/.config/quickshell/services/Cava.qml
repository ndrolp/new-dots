import Quickshell.Io
import Quickshell.Services.Pipewire
import QtQuick
import "CavaOutput.js" as CavaOutput

// The one cava process the whole shell shares. It runs only while some bar
// draws the Cava bar element (see setDrawing) and listens to the default
// audio output, restarting when the default changes so it follows it. When
// it starts, stops, restarts and retries is decided in CavaOutput.js; this
// only carries it out.
QtObject {
    id: root

    // How many bars cava computes: the most any drawn Cava bar element asks
    // for (its `barCount`); each resamples the frame down to its own.
    readonly property int barCount: CavaOutput.sharedBarCount(drawnElements.map(element => element.barCount))
    // The latest frame, one height from 0 to 1 per bar; flat while cava
    // isn't running.
    property var heights: CavaOutput.flatHeights(barCount)
    // The Cava bar elements drawing right now.
    property var drawnElements: []
    readonly property bool needed: drawnElements.length > 0
    // What the Bar section says under Cava while cava can't run ("" while it
    // runs or no bar draws it).
    readonly property string failureHint: runState.failureHint
    // When cava runs (CavaOutput.stopped and the functions after it).
    property var runState: CavaOutput.stopped

    // Called by each Cava bar element when it starts or stops being drawn.
    function setDrawing(element, drawing) {
        const others = drawnElements.filter(entry => entry !== element);
        drawnElements = drawing ? others.concat([element]) : others;
    }

    // A planned restart, so cava follows a new default output or bar count.
    function restart() {
        follow(CavaOutput.restartAsked(runState));
    }

    // Moves to the `next` run state and starts, stops or waits to match it.
    function follow(next) {
        runState = next;
        retry.interval = next.retryDelay;
        retry.running = next.retrying;
        if (cava.running !== next.running)
            cava.running = next.running;
    }

    onNeededChanged: follow(CavaOutput.drawnChanged(runState, needed))
    onBarCountChanged: restart()

    // Starts cava again a while after it failed.
    property var retry: Timer {
        id: retry

        onTriggered: root.follow(CavaOutput.retryDue(root.runState))
    }

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
            onRead: data => {
                if (!root.runState.printedFrame)
                    root.runState = CavaOutput.framePrinted(root.runState);
                root.heights = CavaOutput.frameHeights(data, root.barCount);
            }
        }

        // Flat bars until cava prints again.
        onExited: exitCode => {
            root.heights = CavaOutput.flatHeights(root.barCount);
            root.follow(CavaOutput.exited(root.runState, exitCode));
        }
    }
}
