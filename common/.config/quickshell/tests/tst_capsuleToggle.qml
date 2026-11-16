import QtQuick
import QtTest
import "../components/bar"

// SUPER+I expands the capsule and collapses it again; the pointer entering
// and leaving the capsule also ends it.
TestCase {
    name: "CapsuleToggle"

    Component {
        id: toggleComponent

        CapsuleToggle {}
    }

    function capsuleToggle() {
        return createTemporaryObject(toggleComponent, this);
    }

    function test_itStartsCollapsed() {
        compare(capsuleToggle().toggled, false);
    }

    // Pressing it expands the capsule, and pressing it again collapses it.
    function test_pressingItAgainCollapsesIt() {
        const capsule = capsuleToggle();

        capsule.toggle();
        compare(capsule.toggled, true);
        capsule.toggle();
        compare(capsule.toggled, false);
    }

    // It stays expanded while the pointer is elsewhere, and while it is over
    // the capsule.
    function test_itStaysExpandedUntilThePointerLeaves() {
        const capsule = capsuleToggle();
        capsule.toggle();

        wait(500);
        capsule.hovering = true;
        compare(capsule.toggled, true);
        capsule.hovering = false;
        compare(capsule.toggled, false);
    }
}
