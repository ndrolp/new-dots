import QtQuick
import QtTest
import "../components/bar"
import "../config/Motion.js" as Motion

// A capsule's contents crossfade when what it shows changes: the old view
// fades and shrinks away, then the new one shows, waits a third of the
// shape's spring and fades and grows in.
TestCase {
    name: "CapsuleContentTransition"
    width: 200
    height: 100
    visible: true
    when: windowShown

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
        compare(shown.contentsOpacity, 1);
        compare(shown.contentsScale, 1);
    }

    // The old view stays while it fades and shrinks to 0.95; the new one
    // replaces it once it has gone, and fades and grows in.
    function test_aNewViewReplacesTheOldOnceItHasFaded() {
        const shown = createTemporaryObject(transition, this);

        shown.key = "expanded";
        compare(shown.shownKey, "rest");
        verify(shown.changing);
        tryVerify(() => shown.contentsOpacity < 1 && shown.contentsScale < 1, 100);
        tryCompare(shown, "shownKey", "expanded", 300);
        verify(shown.contentsOpacity < 0.01);
        fuzzyCompare(shown.contentsScale, 0.95, 0.001);
        tryCompare(shown, "contentsOpacity", 1, 600);
        compare(shown.contentsScale, 1);
        verify(!shown.changing);
    }

    // Its own opacity and scale are its contents', so it can wrap them.
    function test_itFadesWhatItWraps() {
        const shown = createTemporaryObject(transition, this);

        shown.key = "change";
        tryVerify(() => shown.opacity < 1, 100);
        compare(shown.opacity, shown.contentsOpacity);
        compare(shown.scale, shown.contentsScale);
    }

    // Changing again while the old view fades lands on the latest.
    function test_aSecondChangeMidFadeLandsOnTheLatest() {
        const shown = createTemporaryObject(transition, this);

        shown.key = "expanded";
        shown.key = "change";
        tryCompare(shown, "shownKey", "change", 300);
        tryCompare(shown, "changing", false, 600);
        compare(shown.shownKey, "change");
    }

    function test_reduceMotionSwapsAtOnce() {
        const shown = createTemporaryObject(transition, this, { motion: Motion.motion(true) });

        shown.key = "expanded";

        compare(shown.shownKey, "expanded");
        compare(shown.contentsOpacity, 1);
        verify(!shown.changing);
    }
}
