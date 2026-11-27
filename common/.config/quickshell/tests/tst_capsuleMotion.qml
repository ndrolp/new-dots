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

    // Whatever moves with the capsule as it expands or collapses (its
    // solidity, its workspace chips) takes the same spring: expanding
    // overshoots, collapsing doesn't bounce.
    function test_expandingOrCollapsingTakesItsSpring() {
        compare(CapsuleMotion.springFor(motion, true), motion.capsule.expand);
        compare(CapsuleMotion.springFor(motion, false), motion.capsule.collapse);
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

    // Both halves of a crossfade run from the moment the view changes, while
    // the capsule's shape springs: the old contents are gone before the new
    // ones start fading in, a third of the way into the spring.
    function test_theOldContentsAreGoneBeforeTheNewFadeIn() {
        const third = motion.capsule.expand.duration / 3;

        compare(CapsuleMotion.contents(motion, Math.floor(third), false).opacity, 0);
        compare(CapsuleMotion.contents(motion, Math.floor(third), true).opacity, 0);
        verify(CapsuleMotion.contents(motion, Math.ceil(third) + 20, true).opacity > 0);
    }

    // How long a crossfade runs: until the new contents are fully in.
    function test_aCrossfadesLength() {
        compare(CapsuleMotion.contentsLength(motion), 317);
        compare(CapsuleMotion.contentsLength(Motion.motion(true)), 0);
    }
    // Expanding, a row's elements enter from the centre outwards: the middle
    // one first (both middle ones, in an even row), then each pair either
    // side of them, and each slides out to its place from the centre's side:
    // those left of the centre from the right (1), those right of it from
    // the left (-1), the very centre in place (0).
    function test_aRowEntersFromTheCentreOut_data() {
        return [
            { tag: "none", count: 0, order: [] },
            { tag: "one", count: 1, order: [{ step: 0, side: 0 }] },
            { tag: "two", count: 2, order: [{ step: 0, side: 1 }, { step: 0, side: -1 }] },
            { tag: "five", count: 5, order: [
                { step: 2, side: 1 }, { step: 1, side: 1 }, { step: 0, side: 0 },
                { step: 1, side: -1 }, { step: 2, side: -1 }
            ] },
            { tag: "six", count: 6, order: [
                { step: 2, side: 1 }, { step: 1, side: 1 }, { step: 0, side: 1 },
                { step: 0, side: -1 }, { step: 1, side: -1 }, { step: 2, side: -1 }
            ] }
        ];
    }

    function test_aRowEntersFromTheCentreOut(data) {
        compare(CapsuleMotion.centreOut(data.count), data.order);
    }
    // Expanding, each step of a row enters 20 ms after the one before,
    // fading in and sliding 6 px to its place, easing out, and the last one
    // is in as the expanding spring settles (350 ms): with three steps each
    // takes 310 ms.
    function test_eachStepEntersAfterTheOneBefore_data() {
        return [
            { tag: "first, at the start", elapsed: 0, step: 0, look: { opacity: 0, slide: 6 } },
            { tag: "second, still waiting", elapsed: 20, step: 1, look: { opacity: 0, slide: 6 } },
            { tag: "last, halfway in", elapsed: 195, step: 2, look: { opacity: 0.875, slide: 0.75 } },
            { tag: "first, in", elapsed: 310, step: 0, look: { opacity: 1, slide: 0 } },
            { tag: "last, in as the spring settles", elapsed: 350, step: 2, look: { opacity: 1, slide: 0 } },
            { tag: "long after", elapsed: 2000, step: 1, look: { opacity: 1, slide: 0 } }
        ];
    }

    function test_eachStepEntersAfterTheOneBefore(data) {
        const look = CapsuleMotion.entering(motion, data.elapsed, data.step, 3);
        fuzzyCompare(look.opacity, data.look.opacity, 0.0001);
        fuzzyCompare(look.slide, data.look.slide, 0.0001);
    }

    // However long the row, each step takes at least 120 ms to enter, even
    // if the last then settles after the spring.
    function test_aLongRowsStepsStillTakeAMoment() {
        const look = CapsuleMotion.entering(motion, 60, 0, 20);
        fuzzyCompare(look.opacity, 0.875, 0.0001);
    }

    // With reduce motion every step is in at once.
    function test_reduceMotionEntersAtOnce() {
        compare(CapsuleMotion.entering(Motion.motion(true), 0, 4, 5), { opacity: 1, slide: 0 });
    }

    // How long an entry of so many steps runs: until its last step is in,
    // as the expanding spring settles, later for a long row.
    function test_anEntrysLength() {
        compare(CapsuleMotion.entryLength(motion, 3), 350);
        compare(CapsuleMotion.entryLength(motion, 20), 500);
        compare(CapsuleMotion.entryLength(Motion.motion(true), 3), 0);
    }

    // A row's elements, by id and where each starts along it, enter from
    // its centre out whatever order they are listed in; with how many steps
    // its entry takes.
    function test_aRowsElementsEnterFromItsCentre() {
        const entry = CapsuleMotion.rowEntry({
            battery: { start: 120 },
            clock: { start: 0 },
            network: { start: 60 }
        });

        compare(entry, {
            steps: 2,
            places: {
                clock: { step: 1, side: 1 },
                network: { step: 0, side: 0 },
                battery: { step: 1, side: -1 }
            }
        });
        compare(CapsuleMotion.rowEntry({}), { steps: 0, places: {} });
    }

    readonly property var entry: CapsuleMotion.rowEntry({
        clock: { start: 0 }, network: { start: 60 }, battery: { start: 120 }
    })
    readonly property var crossfade: ({ opacity: 0.5, scale: 0.97 })

    // While the row enters, each of its elements looks as its step does,
    // unscaled and slid to the side it comes from.
    function test_anEnteringElementTakesItsStepsLook() {
        const look = CapsuleMotion.rowLook(motion, {
            entering: true, elapsed: 20 + 165, entry: entry, crossfade: crossfade
        }, "battery");

        fuzzyCompare(look.opacity, 0.875, 0.0001);
        compare(look.scale, 1);
        fuzzyCompare(look.slide, -0.75, 0.0001);
    }

    // Otherwise, or for an element not in the row, it takes the crossfade's
    // look, in place.
    function test_otherwiseAnElementTakesTheCrossfade_data() {
        return [
            { tag: "not entering", entering: false, element: "clock" },
            { tag: "not in the row", entering: true, element: "media" }
        ];
    }

    function test_otherwiseAnElementTakesTheCrossfade(data) {
        const look = CapsuleMotion.rowLook(motion, {
            entering: data.entering, elapsed: 100, entry: entry, crossfade: crossfade
        }, data.element);

        compare(look, { opacity: 0.5, scale: 0.97, slide: 0 });
    }

    // The glance's cards enter just after the row, one after another left to
    // right: card i takes the step after the row's last, plus i, of all the
    // steps, and slides in from the left. 2 row steps and 2 cards make 4
    // steps of 290 ms, 20 ms apart.
    function test_theGlanceCardsEnterAfterTheRow_data() {
        return [
            { tag: "first card waiting", index: 0, elapsed: 39, opacity: 0, slide: -6 },
            { tag: "first card halfway", index: 0, elapsed: 40 + 145, opacity: 0.875, slide: -0.75 },
            { tag: "second card waiting", index: 1, elapsed: 59, opacity: 0, slide: -6 },
            { tag: "second card halfway", index: 1, elapsed: 60 + 145, opacity: 0.875, slide: -0.75 },
            { tag: "second card in", index: 1, elapsed: 350, opacity: 1, slide: 0 }
        ];
    }

    function test_theGlanceCardsEnterAfterTheRow(data) {
        const look = CapsuleMotion.cardLook(motion, {
            entering: true, elapsed: data.elapsed, entry: entry, crossfade: crossfade
        }, data.index, 2);

        fuzzyCompare(look.opacity, data.opacity, 0.0001);
        compare(look.scale, 1);
        fuzzyCompare(look.slide, data.slide, 0.0001);
    }

    // With reduce motion every card is in at once.
    function test_withReduceMotionTheCardsAreInAtOnce() {
        const look = CapsuleMotion.cardLook(Motion.motion(true), {
            entering: true, elapsed: 0, entry: entry, crossfade: crossfade
        }, 1, 2);

        compare(look, { opacity: 1, scale: 1, slide: 0 });
    }

    // Otherwise a card takes the crossfade's look, in place.
    function test_aCardNotEnteringTakesTheCrossfade() {
        const look = CapsuleMotion.cardLook(motion, {
            entering: false, elapsed: 0, entry: entry, crossfade: crossfade
        }, 0, 2);

        compare(look, { opacity: 0.5, scale: 0.97, slide: 0 });
    }
}
