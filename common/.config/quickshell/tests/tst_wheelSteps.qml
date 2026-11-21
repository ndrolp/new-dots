import QtQuick
import QtTest
import "../components/bar/WheelSteps.js" as WheelSteps

// How scrolling turns into steps, at most one per gesture: one per wheel
// notch, one per touchpad swipe however long it runs.
TestCase {
    name: "WheelSteps"

    // A wheel event as QML's WheelEvent gives it: angleDelta.y, pixelDelta.y
    // and Qt's scroll phase (0 none, 1 begin, 2 update, 3 end, 4 momentum).
    function wheel(angle, pixel, phase) {
        return { angleDelta: { x: 0, y: angle }, pixelDelta: { x: 0, y: pixel || 0 }, phase: phase || 0 };
    }

    // The steps a run of [event, time] pairs takes, in order.
    function steps(events) {
        let state = WheelSteps.initial();
        const taken = [];
        for (const [event, now] of events) {
            const result = WheelSteps.take(state, event, now);
            state = result.state;
            if (result.step !== 0)
                taken.push(result.step);
        }
        return taken;
    }

    function test_aWheelNotchDownStepsForwardAndUpStepsBack() {
        compare(steps([[wheel(-120), 0]]), [1]);
        compare(steps([[wheel(120), 0]]), [-1]);
    }

    function test_aHighResolutionWheelStepsOncePerWholeNotch() {
        const eighths = [];
        for (let index = 0; index < 12; index++)
            eighths.push([wheel(-15), index * 10]);

        compare(steps(eighths.slice(0, 7)), []);
        compare(steps(eighths), [1]);
    }

    function test_oneEventNeverStepsMoreThanOnce() {
        compare(steps([[wheel(-360), 0]]), [1]);
    }

    // A touchpad swipe: begin, `updates` updates of `angle` each, 10 ms
    // apart from `start`, then end.
    function swipe(angle, updates, start) {
        const events = [[wheel(0, 0, 1), start]];
        for (let index = 1; index <= updates; index++)
            events.push([wheel(angle, angle / 2, 2), start + index * 10]);
        events.push([wheel(0, 0, 3), start + (updates + 1) * 10]);
        return events;
    }

    function test_aLongTouchpadSwipeStepsOnce() {
        compare(steps(swipe(-60, 30, 0)), [1]);
        compare(steps(swipe(60, 30, 0)), [-1]);
    }

    function test_aShortTouchpadSwipeDoesntStep() {
        compare(steps(swipe(-30, 3, 0)), []);
    }

    function test_eachTouchpadSwipeStepsOnce() {
        compare(steps(swipe(-60, 30, 0).concat(swipe(-60, 30, 400))), [1, 1]);
    }

    function test_theMomentumAfterASwipeDoesntStepAgain() {
        const momentum = [];
        for (let index = 0; index < 20; index++)
            momentum.push([wheel(-200, -100, 4), 400 + index * 10]);

        compare(steps(swipe(-60, 30, 0).concat(momentum)), [1]);
    }

    // A touchpad swipe with no phases, only pixel deltas.
    function unphasedSwipe(angle, updates, start) {
        const events = [];
        for (let index = 0; index < updates; index++)
            events.push([wheel(angle, angle / 2), start + index * 10]);
        return events;
    }

    function test_aTouchpadWithNoPhasesStepsOncePerSwipe() {
        compare(steps(unphasedSwipe(-60, 30, 0)), [1]);
        compare(steps(unphasedSwipe(-60, 30, 0).concat(unphasedSwipe(-60, 30, 800))), [1, 1]);
    }

    function test_eachNotchStepsOnceEvenInQuickSuccession() {
        compare(steps([[wheel(-120), 0], [wheel(-120), 20], [wheel(-120), 40]]), [1, 1, 1]);
    }
}
