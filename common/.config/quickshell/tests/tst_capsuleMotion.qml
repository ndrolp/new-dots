import QtQuick
import QtTest
import "../config/Motion.js" as Motion
import "../components/bar/CapsuleMotion.js" as CapsuleMotion

// How the capsule moves: which spring a size change takes, and how its
// contents look a given time into a transition.
TestCase {
    name: "CapsuleMotion"

    readonly property var motion: Motion.motion(false)
    readonly property var rest: ({ x: 800, y: 0, width: 320, height: 32, radius: 16 })

    // Growing in either direction expands, overshooting; shrinking in both
    // collapses, without bounce.
    function test_aSizeChangeTakesItsSpring_data() {
        return [
            { tag: "wider", to: { width: 400, height: 32 }, spring: "expand" },
            { tag: "deeper", to: { width: 320, height: 300 }, spring: "expand" },
            { tag: "narrower but deeper", to: { width: 200, height: 300 }, spring: "expand" },
            { tag: "narrower", to: { width: 200, height: 32 }, spring: "collapse" },
            { tag: "smaller", to: { width: 200, height: 20 }, spring: "collapse" },
            { tag: "unchanged", to: { width: 320, height: 32 }, spring: "collapse" }
        ];
    }

    function test_aSizeChangeTakesItsSpring(data) {
        compare(CapsuleMotion.spring(motion, rest, data.to), motion.capsule[data.spring]);
    }

    // Incoming contents wait a third of the expanding spring (117 ms), then
    // fade and grow from 0.95 to 1 over 200 ms, easing out.
    function test_incomingContentsWaitThenFadeAndGrowIn_data() {
        return [
            { tag: "at the start", elapsed: 0, look: { opacity: 0, scale: 0.95 } },
            { tag: "still waiting", elapsed: 117, look: { opacity: 0, scale: 0.95 } },
            { tag: "halfway in", elapsed: 217, look: { opacity: 0.875, scale: 0.99375 } },
            { tag: "in", elapsed: 317, look: { opacity: 1, scale: 1 } },
            { tag: "long after", elapsed: 2000, look: { opacity: 1, scale: 1 } }
        ];
    }

    function test_incomingContentsWaitThenFadeAndGrowIn(data) {
        const look = CapsuleMotion.contents(motion, data.elapsed, true);
        fuzzyCompare(look.opacity, data.look.opacity, 0.0001);
        fuzzyCompare(look.scale, data.look.scale, 0.0001);
    }

    // Outgoing contents fade and shrink to 0.95 at once, over 110 ms, easing
    // out.
    function test_outgoingContentsFadeAndShrinkAway_data() {
        return [
            { tag: "at the start", elapsed: 0, look: { opacity: 1, scale: 1 } },
            { tag: "halfway", elapsed: 55, look: { opacity: 0.125, scale: 0.95625 } },
            { tag: "gone", elapsed: 110, look: { opacity: 0, scale: 0.95 } },
            { tag: "long after", elapsed: 2000, look: { opacity: 0, scale: 0.95 } }
        ];
    }

    function test_outgoingContentsFadeAndShrinkAway(data) {
        const look = CapsuleMotion.contents(motion, data.elapsed, false);
        fuzzyCompare(look.opacity, data.look.opacity, 0.0001);
        fuzzyCompare(look.scale, data.look.scale, 0.0001);
    }

    // With reduce motion contents are where they end at once.
    function test_reduceMotionShowsContentsAtOnce() {
        const instant = Motion.motion(true);

        compare(CapsuleMotion.contents(instant, 0, true), { opacity: 1, scale: 1 });
        compare(CapsuleMotion.contents(instant, 0, false), { opacity: 0, scale: 0.95 });
    }

    // How long each half of a contents transition runs: out, or the wait
    // and in.
    function test_aContentsTransitionsLength() {
        compare(CapsuleMotion.contentsLength(motion, false), 110);
        compare(CapsuleMotion.contentsLength(motion, true), 317);
        compare(CapsuleMotion.contentsLength(Motion.motion(true), true), 0);
    }
}
