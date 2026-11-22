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

    // The capsule's springs: expanding overshoots slightly and settles in
    // about 350 ms; collapsing is a bit faster and doesn't bounce.
    function test_theCapsuleExpandsWithASlightOvershoot() {
        const expand = Motion.motion(false).capsule.expand;

        compare(expand.duration, 350);
        compare(expand.easing, Easing.OutBack);
        verify(expand.overshoot > 0 && expand.overshoot < 1.70158, "slighter than OutBack's default");
    }

    function test_theCapsuleCollapsesFasterWithoutBounce() {
        const collapse = Motion.motion(false).capsule.collapse;

        verify(collapse.duration < 350);
        verify(collapse.duration >= 250);
        compare(collapse.easing, Easing.OutCubic);
    }

    // Its contents: the outgoing fade and shrink to 0.95, the incoming grow
    // back from 0.95 starting a third of the way into the expanding spring.
    function test_capsuleContentsCrossfadeWithASlightScale() {
        const capsule = Motion.motion(false).capsule;

        compare(capsule.contentsScale, 0.95);
        compare(capsule.contentsDelay, 117);
        verify(capsule.contentsOut > 0 && capsule.contentsOut < capsule.contentsDelay + 1);
        verify(capsule.contentsIn > 0);
    }

    function test_reduceMotionMakesTheCapsuleInstant() {
        const capsule = Motion.motion(true).capsule;

        compare([capsule.expand.duration, capsule.collapse.duration, capsule.contentsOut,
            capsule.contentsDelay, capsule.contentsIn], [0, 0, 0, 0, 0]);
        compare(capsule.contentsScale, 0.95);
    }
}
