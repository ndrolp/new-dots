import QtQuick
import QtTest
import "../components/bar"

// When hovering the capsule expands it: after a short hover, and it stays
// expanded a while after the pointer leaves.
TestCase {
    name: "CapsuleHover"

    Component {
        id: hoverComponent

        CapsuleHover {}
    }

    function hover() {
        return createTemporaryObject(hoverComponent, this);
    }

    function test_itStartsCollapsed() {
        compare(hover().expanded, false);
    }

    // Hovering it for about 150 ms expands it.
    function test_hoveringExpandsAfterAMoment() {
        const capsule = hover();

        capsule.hovering = true;
        wait(80);
        compare(capsule.expanded, false);
        tryCompare(capsule, "expanded", true, 300);
    }

    // A quick pass over it doesn't expand it.
    function test_aQuickPassDoesNotExpand() {
        const capsule = hover();

        capsule.hovering = true;
        wait(60);
        capsule.hovering = false;
        wait(250);
        compare(capsule.expanded, false);
    }

    // Leaving it collapses it about 400 ms later.
    function test_leavingCollapsesAfterAWhile() {
        const capsule = hover();
        capsule.hovering = true;
        tryCompare(capsule, "expanded", true, 300);

        capsule.hovering = false;
        wait(250);
        compare(capsule.expanded, true);
        tryCompare(capsule, "expanded", false, 400);
    }

    // Coming back before then keeps it expanded.
    function test_comingBackKeepsItExpanded() {
        const capsule = hover();
        capsule.hovering = true;
        tryCompare(capsule, "expanded", true, 300);

        capsule.hovering = false;
        wait(200);
        capsule.hovering = true;
        wait(400);
        compare(capsule.expanded, true);
    }
}
