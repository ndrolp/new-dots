import QtQuick
import "CapsuleMotion.js" as CapsuleMotion

// A capsule's contents crossfading with a slight scale when what they show
// changes, by `key` (a view's name: "rest", "expanded", "change", a media or
// pomodoro view…). The new view is shown (`shownKey`) at once, which is what
// moves the capsule's shape (CapsuleSurface.qml springs to fit it), so the
// shape never waits. Only a frame goes by first (`capturing`), for whoever
// draws the old view to capture it as it is. Then, while the shape moves,
// the old view (`previousKey`) fades and shrinks to 0.95 and the new one
// waits a third of that spring before fading and growing in
// (CapsuleMotion.contents, timings from Motion.js `capsule`). Reduce motion
// swaps at once.
//
// Use it two ways:
// - Wrap a view: put the contents inside and switch them on `shownKey`; its
//   own opacity and scale are the new view's. Draw `previousKey` with
//   `outgoingOpacity` and `outgoingScale` to fade the old one out.
// - Drive contents elsewhere: bind their opacity and scale to
//   `contentsOpacity` and `contentsScale` and what they show to `shownKey`;
//   a capture of the old ones (Bar.qml's row) takes `outgoingOpacity` and
//   `outgoingScale`, captured while `capturing`.
Item {
    id: root

    // The view to show; a change crossfades to it.
    property var key
    // Appearance.motion, with its `capsule` timings.
    required property var motion
    // How long, in ms, the new view's contents take to come in, when they
    // take longer than a crossfade (a row entering one after another,
    // CapsuleMotion.entryLength): it runs that long, `elapsed` counting on.
    // Read all the way through, not once at the swap: the new view's contents
    // can arrive a moment after it shows, and their length with them.
    property real length: 0
    // How long, in ms, the crossfade runs now: the new view's `length`, never
    // less than a crossfade.
    readonly property real runLength: Math.max(CapsuleMotion.contentsLength(motion), length)
    // The view shown now: the new one from the frame after a change.
    property var shownKey
    // The view fading out while the shape moves, or null.
    property var previousKey: null
    // Whether a crossfade runs.
    readonly property bool changing: phase !== ""
    // Whether the old view is being captured, the frame before the swap.
    readonly property bool capturing: phase === "capture"
    // How the new contents and the old look now (CapsuleMotion.contents).
    readonly property var look: phase === "moving" ? CapsuleMotion.contents(motion, elapsed, true)
        : { opacity: 1, scale: 1 }
    readonly property var outgoing: phase === "moving" ? CapsuleMotion.contents(motion, elapsed, false)
        : { opacity: phase === "capture" ? 1 : 0, scale: 1 }
    readonly property real contentsOpacity: look.opacity
    readonly property real contentsScale: look.scale
    readonly property real outgoingOpacity: outgoing.opacity
    readonly property real outgoingScale: outgoing.scale

    // "capture" the frame before the swap, "moving" while the shape moves
    // and both views fade, "" at rest; and how far into "moving" it is, in ms.
    property string phase: ""
    property real elapsed: 0
    // Set once built: the first key shows at once.
    property bool ready: false

    opacity: contentsOpacity
    scale: contentsScale

    // Shows the latest key and starts both fades as the shape starts moving.
    function swap() {
        capture.stop();
        timeline.stop();
        elapsed = 0;
        previousKey = shownKey;
        phase = "moving";
        shownKey = key;
        runFrom(0);
    }

    // Runs the timeline on from `from` ms to the end of the crossfade, or
    // settles if it is past it already.
    function runFrom(from) {
        timeline.stop();
        if (from >= runLength) {
            elapsed = runLength;
            settle();
            return;
        }
        timeline.from = from;
        timeline.to = runLength;
        timeline.duration = runLength - from;
        timeline.start();
    }

    // A length that arrives while it moves sets where it ends.
    onRunLengthChanged: {
        if (phase === "moving")
            runFrom(elapsed);
    }

    function settle() {
        phase = "";
        previousKey = null;
    }

    Component.onCompleted: {
        shownKey = key;
        ready = true;
    }

    onKeyChanged: {
        if (!ready || phase === "capture")
            return;
        if (CapsuleMotion.contentsLength(motion) <= 0) {
            timeline.stop();
            settle();
            shownKey = key;
            return;
        }
        timeline.stop();
        phase = "capture";
        capture.frames = 0;
        capture.start();
    }

    // Waits one rendered frame: the first tick comes before the frame that
    // captures the old view is drawn, the second after.
    FrameAnimation {
        id: capture

        property int frames: 0

        onTriggered: {
            frames++;
            if (frames >= 2)
                root.swap();
        }
    }

    NumberAnimation {
        id: timeline

        target: root
        property: "elapsed"
        onFinished: root.settle()
    }
}
