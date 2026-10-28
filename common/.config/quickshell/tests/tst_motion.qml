import QtQuick
import QtTest
import "../config/Motion.js" as Motion

// How long animations take: the shared durations every animation reads, and
// reduce motion making them instant.
TestCase {
    name: "Motion"

    function test_animationsTakeTheSharedDurations() {
        const durations = Motion.durations(false);

        compare(durations.brief, 90);
        compare(durations.short, 140);
        compare(durations.medium, 180);
        compare(durations.long, 220);
        compare(durations.frame, 50);
    }

    function test_reduceMotionMakesEveryAnimationInstant() {
        compare(Motion.durations(true), { brief: 0, short: 0, medium: 0, long: 0, frame: 0 });
    }

    function test_aMissingSettingKeepsTheAnimations() {
        compare(Motion.durations(undefined), Motion.durations(false));
    }
}
