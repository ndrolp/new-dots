import QtQuick
import "CapsuleMotion.js" as CapsuleMotion

// A capsule's contents crossfading with a slight scale when what they show
// changes, by `key` (a view's name: "rest", "expanded", "change", a media or
// pomodoro view…). The old view stays shown (`shownKey`) while it fades and
// shrinks to 0.95; then the new one is shown, which is what moves the
// capsule's shape (CapsuleSurface.qml springs to fit it), and it waits a
// third of that spring before fading and growing in (CapsuleMotion.contents,
// timings from Motion.js `capsule`). Reduce motion swaps at once.
//
// Use it two ways:
// - Wrap a view: put the contents inside and switch them on `shownKey`; its
//   own opacity and scale are the contents'.
// - Drive contents elsewhere: bind their opacity and scale to
//   `contentsOpacity` and `contentsScale` and what they show to `shownKey`.
Item {
    id: root

    // The view to show; a change crossfades to it.
    property var key
    // Appearance.motion, with its `capsule` timings.
    required property var motion
    // The view shown now: the old one until it has faded out.
    property var shownKey
    // Whether a crossfade runs.
    readonly property bool changing: phase !== ""
    // How the contents look now (CapsuleMotion.contents).
    readonly property var look: phase === "" ? { opacity: 1, scale: 1 }
        : CapsuleMotion.contents(motion, elapsed, phase === "in")
    readonly property real contentsOpacity: look.opacity
    readonly property real contentsScale: look.scale

    // "out" while the old view fades, "in" while the new one does, "" at
    // rest; and how far into that half it is, in ms.
    property string phase: ""
    property real elapsed: 0
    // Set once built: the first key shows at once.
    property bool ready: false

    opacity: contentsOpacity
    scale: contentsScale

    function run(half) {
        timeline.stop();
        phase = half;
        elapsed = 0;
        timeline.to = CapsuleMotion.contentsLength(motion, half === "in");
        timeline.duration = timeline.to;
        if (timeline.duration <= 0)
            finished();
        else
            timeline.start();
    }

    function finished() {
        if (phase === "out") {
            shownKey = key;
            run("in");
        } else {
            phase = "";
        }
    }

    Component.onCompleted: {
        shownKey = key;
        ready = true;
    }

    onKeyChanged: {
        if (!ready || phase === "out")
            return;
        if (CapsuleMotion.contentsLength(motion, false) <= 0) {
            timeline.stop();
            phase = "";
            shownKey = key;
            return;
        }
        run("out");
    }

    NumberAnimation {
        id: timeline

        target: root
        property: "elapsed"
        from: 0
        onFinished: root.finished()
    }
}
