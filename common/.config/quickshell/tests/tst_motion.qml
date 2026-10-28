import QtQuick
import QtTest
import "../config/Motion.js" as Motion

// How long animations take: the shared durations every animation reads, and
// reduce motion making them instant.
TestCase {
    name: "Motion"

    function test_animationsTakeTheSharedDurations() {
        const durations = Motion.motion(false);

        compare(durations.brief, 90);
        compare(durations.short, 140);
        compare(durations.medium, 180);
        compare(durations.long, 220);
        compare(durations.frame, 50);
    }

    function test_reduceMotionMakesEveryAnimationInstant() {
        const motion = Motion.motion(true);
        compare([motion.brief, motion.short, motion.medium, motion.long, motion.frame], [0, 0, 0, 0, 0]);
    }

    function test_aMissingSettingKeepsTheAnimations() {
        compare(Motion.motion(undefined), Motion.motion(false));
    }

    // The easing travels in the same object as the durations, so a host
    // hands one `motion` to whatever it animates.
    function test_animationsEaseOutCubic() {
        compare(Motion.motion(false).easing, Easing.OutCubic);
        compare(Motion.motion(true).easing, Easing.OutCubic);
    }
}
