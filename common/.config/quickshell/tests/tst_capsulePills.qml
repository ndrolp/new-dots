import QtQuick
import QtTest
import "../components/bar/CapsulePills.js" as CapsulePills

// Which of its monitor's workspaces the capsule gives a pill at rest: the
// active one, empty or not, and every one with windows; an empty one has
// none.
TestCase {
    name: "CapsulePills"

    // Hyprland's workspaces as the workspace service shows them.
    function workspaces(active, occupied) {
        return {
            isActive: id => id === active,
            isOccupied: id => occupied.indexOf(id) !== -1
        };
    }

    // The pills of workspaces 1 to 4.
    function pills(service) {
        return [1, 2, 3, 4].filter(id => CapsulePills.hasRestingPill(id, service));
    }

    function test_anEmptyWorkspaceHasNoPill() {
        compare(pills(workspaces(1, [1, 3])), [1, 3]);
    }

    function test_theActiveWorkspaceHasAPillEvenWhenEmpty() {
        compare(pills(workspaces(2, [1, 3])), [1, 2, 3]);
    }

    function test_withNoWindowsOnlyTheActiveOneHasAPill() {
        compare(pills(workspaces(4, [])), [4]);
    }
}
