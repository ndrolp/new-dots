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
        timeline.duration = CapsuleMotion.contentsLength(motion);
        timeline.to = timeline.duration;
        timeline.start();
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
        from: 0
        onFinished: root.settle()
    }
}
