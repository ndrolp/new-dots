import QtQuick
import QtTest
import "../components/WheelSteps.js" as WheelSteps

// What a run of wheel events steps through: a mouse wheel one step per notch,
// a touchpad gesture at most one step however far it goes. Scrolling down
// steps forward (1), up back (-1).
TestCase {
    name: "WheelSteps"

    // Feeds the scrolls in order and gives the steps they make, without the
    // zeroes.
    function steps(scrolls) {
        let state = WheelSteps.start();
        const made = [];

        for (const scroll of scrolls) {
            const result = WheelSteps.next(state, Object.assign({
                angleDelta: 0, pixelDelta: 0, phase: Qt.NoScrollPhase, time: 0
            }, scroll));
            state = result.state;
            if (result.step !== 0)
                made.push(result.step);
        }

        return made;
    }

    function test_aWheelNotchDownStepsForwardAndUpStepsBack() {
        compare(steps([{ angleDelta: -120 }]), [1]);
        compare(steps([{ angleDelta: 120 }]), [-1]);
    }

    function test_eachWheelNotchStepsOnceEvenInQuickSuccession() {
        compare(steps([
            { angleDelta: -120, time: 0 },
            { angleDelta: -120, time: 20 },
            { angleDelta: -120, time: 40 }
        ]), [1, 1, 1]);
    }

    // A high-resolution wheel sends a notch in parts.
    function test_partsOfANotchAddUpToOneStep() {
        compare(steps([
            { angleDelta: -40, time: 0 },
            { angleDelta: -40, time: 10 },
            { angleDelta: -40, time: 20 }
        ]), [1]);
        compare(steps([{ angleDelta: -60 }]), []);
    }

    // Leftovers from long ago don't add to a new scroll.
    function test_partsOfANotchFarApartDontAddUp() {
        compare(steps([
            { angleDelta: -60, time: 0 },
            { angleDelta: -60, time: 2000 }
        ]), []);
    }

    function test_aTouchpadGestureStepsAtMostOnce() {
        const updates = [];
        for (let index = 1; index <= 20; index++)
            updates.push({ angleDelta: -60, pixelDelta: -30, phase: Qt.ScrollUpdate, time: index * 10 });

        compare(steps([{ phase: Qt.ScrollBegin }].concat(updates,
            [{ phase: Qt.ScrollEnd, time: 300 }, { angleDelta: -60, phase: Qt.ScrollMomentum, time: 310 }])), [1]);
    }

    function test_aShortTouchpadGestureDoesNotStep() {
        compare(steps([
            { phase: Qt.ScrollBegin },
            { angleDelta: -30, pixelDelta: -15, phase: Qt.ScrollUpdate, time: 10 },
            { phase: Qt.ScrollEnd, time: 20 }
        ]), []);
    }

    function test_eachTouchpadGestureStepsOnce() {
        const gesture = (time, delta) => [
            { phase: Qt.ScrollBegin, time: time },
            { angleDelta: delta, pixelDelta: delta / 2, phase: Qt.ScrollUpdate, time: time + 10 },
            { angleDelta: delta, pixelDelta: delta / 2, phase: Qt.ScrollUpdate, time: time + 20 },
            { phase: Qt.ScrollEnd, time: time + 30 }
        ];

        compare(steps(gesture(0, -120).concat(gesture(100, -120), gesture(200, 120))), [1, 1, -1]);
    }

    // A touchpad that reports no gesture phases: its gesture ends once it has
    // been still for a moment.
    function test_aTouchpadWithoutPhasesStepsOncePerGesture() {
        const gesture = time => [0, 10, 20, 30, 40].map(offset =>
            ({ angleDelta: -60, pixelDelta: -30, time: time + offset }));

        compare(steps(gesture(0)), [1]);
        compare(steps(gesture(0).concat(gesture(1000))), [1, 1]);
    }
}
