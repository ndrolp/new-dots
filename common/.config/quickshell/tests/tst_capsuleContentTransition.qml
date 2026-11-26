import QtQuick
import QtTest
import "../components/bar"
import "../components/bar/CapsuleMotion.js" as CapsuleMotion
import "../config/Motion.js" as Motion

// A capsule's contents crossfade when what it shows changes: the new view is
// shown at once, a frame after the old one is captured, so the capsule's
// shape springs to it straight away; the old view fades and shrinks away
// while it moves and the new one fades and grows in from a third of the way
// in. How they look a given time in is CapsuleMotion.contents
// (tst_capsuleMotion.qml); these check the transition follows it, by phase
// and elapsed time rather than the clock.
TestCase {
    name: "CapsuleContentTransition"
    width: 200
    height: 100
    visible: true
    when: windowShown

    readonly property var motion: Motion.motion(false)

    Component {
        id: transition

        CapsuleContentTransition {
            key: "rest"
            motion: Motion.motion(false)
        }
    }

    function test_itShowsItsViewAtFirst() {
        const shown = createTemporaryObject(transition, this);

        compare(shown.shownKey, "rest");
        compare(shown.previousKey, null);
        compare(shown.contentsOpacity, 1);
        compare(shown.contentsScale, 1);
    }

    // The new view is shown before any of the crossfade has run: the old one
    // is still fully there, captured, as the shape starts moving.
    function test_aNewViewIsShownAtOnce() {
        const shown = createTemporaryObject(transition, this);
        let atSwap = null;
        shown.shownKeyChanged.connect(() => {
            atSwap = { elapsed: shown.elapsed, outgoing: shown.outgoingOpacity,
                previous: shown.previousKey, phase: shown.phase };
        });

        shown.key = "expanded";
        verify(shown.changing);
        compare(shown.phase, "capture");
        compare(shown.outgoingOpacity, 1);
        tryCompare(shown, "shownKey", "expanded");
        compare(atSwap, { elapsed: 0, outgoing: 1, previous: "rest", phase: "moving" });
    }

    // While it moves, the old view's look and the new one's are
    // CapsuleMotion.contents at the time elapsed, outgoing and incoming.
    function test_whileMovingBothViewsFollowTheirLook() {
        const shown = createTemporaryObject(transition, this);

        shown.key = "expanded";
        tryCompare(shown, "phase", "moving");
        tryVerify(() => shown.elapsed > 0);
        const elapsed = shown.elapsed;
        const incoming = CapsuleMotion.contents(motion, elapsed, true);
        const outgoing = CapsuleMotion.contents(motion, elapsed, false);
        compare(shown.contentsOpacity, incoming.opacity);
        compare(shown.contentsScale, incoming.scale);
        compare(shown.outgoingOpacity, outgoing.opacity);
        compare(shown.outgoingScale, outgoing.scale);
    }

    function test_itSettlesOnTheNewView() {
        const shown = createTemporaryObject(transition, this);

        shown.key = "expanded";
        tryCompare(shown, "changing", false);
        compare(shown.shownKey, "expanded");
        compare(shown.previousKey, null);
        compare(shown.contentsOpacity, 1);
        compare(shown.contentsScale, 1);
        compare(shown.outgoingOpacity, 0);
    }

    // Its own opacity and scale are the new view's, so it can wrap it.
    function test_itFadesWhatItWraps() {
        const shown = createTemporaryObject(transition, this);

        shown.key = "change";
        tryCompare(shown, "phase", "moving");
        compare(shown.opacity, shown.contentsOpacity);
        compare(shown.scale, shown.contentsScale);
    }

    // Changing again before the swap lands on the latest.
    function test_aSecondChangeBeforeTheSwapLandsOnTheLatest() {
        const shown = createTemporaryObject(transition, this);

        shown.key = "expanded";
        shown.key = "change";
        tryCompare(shown, "changing", false);
        compare(shown.shownKey, "change");
    }

    // Changing again mid-crossfade starts over from what shows then.
    function test_aChangeMidCrossfadeStartsOver() {
        const shown = createTemporaryObject(transition, this);

        shown.key = "expanded";
        tryCompare(shown, "phase", "moving");
        shown.key = "change";
        compare(shown.phase, "capture");
        tryCompare(shown, "shownKey", "change");
        compare(shown.previousKey, "expanded");
        tryCompare(shown, "changing", false);
    }

    // A view whose contents take longer to come in than a crossfade (a row
    // entering one after another, CapsuleMotion.entryLength) keeps it
    // running until they are in.
    function test_aLongerEntryKeepsItRunning() {
        const shown = createTemporaryObject(transition, this, { length: 500 });

        shown.key = "expanded";
        tryVerify(() => shown.elapsed > CapsuleMotion.contentsLength(motion) + 50);
        verify(shown.changing);
        tryCompare(shown, "changing", false);
    }

    // It never ends before the crossfade does.
    function test_itRunsAtLeastAsLongAsACrossfade() {
        const shown = createTemporaryObject(transition, this, { length: 10 });

        shown.key = "expanded";
        tryVerify(() => shown.elapsed > 100);
        verify(shown.changing);
    }

    function test_reduceMotionSwapsAtOnce() {
        const shown = createTemporaryObject(transition, this, { motion: Motion.motion(true) });

        shown.key = "expanded";

        compare(shown.shownKey, "expanded");
        compare(shown.contentsOpacity, 1);
        compare(shown.outgoingOpacity, 0);
        verify(!shown.changing);
    }
}
