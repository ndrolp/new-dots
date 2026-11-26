import QtQuick
import QtTest
import "../components/bar/CapsulePills.js" as CapsulePills

// The capsule's workspace pills: one per workspace of its monitor. At rest a
// bare pill; expanded, a chip with its number or glyph.
TestCase {
    name: "CapsulePills"

    // Hyprland's workspaces as the workspace service shows them: `shown` is
    // the one the monitor "monitor" shows, `focused` the one with focus,
    // which can be on another monitor.
    function workspaces(shown, occupied, urgent, focused) {
        return {
            activeWorkspaceIdForScreen: screen => screen === "monitor" ? shown : -1,
            isActive: id => id === (focused === undefined ? shown : focused),
            isOccupied: id => occupied.indexOf(id) !== -1,
            isUrgent: id => (urgent || []).indexOf(id) !== -1
        };
    }

    // The roles of workspaces 1 to 4 on the monitor.
    function roles(service) {
        return [1, 2, 3, 4].map(id => CapsulePills.role(id, service, "monitor"));
    }

    function test_eachWorkspaceHasARole() {
        compare(roles(workspaces(2, [1, 3, 4], [3])), ["occupied", "shown", "urgent", "occupied"]);
    }

    // The workspace a monitor shows is its shown one, whichever monitor has
    // focus; one asking for attention there is still the shown one.
    function test_theShownWorkspaceIsTheMonitorsNotTheFocusedOne() {
        compare(roles(workspaces(2, [1, 2], [2], 7)), ["occupied", "shown", "empty", "empty"]);
    }

    // A chip shows its workspace's number, or its glyph when the workspaces
    // bar element uses glyphs and has one for it.
    function test_aChipShowsTheNumberOrTheGlyph() {
        const glyphs = { glyphsEnabled: true, glyphs: ["  a ", "", "c"] };

        compare([1, 2, 3, 4].map(id => CapsulePills.label(id, glyphs)), ["a", "2", "c", "4"]);
        compare(CapsulePills.label(1, { glyphsEnabled: false, glyphs: ["a"] }), "1");
    }

    // At rest a pill is 4 deep and twice as long, the shown one twice that;
    // expanded, a chip is `chipDepth` deep and its label plus half that on
    // either side, the shown one half a chip longer on either side.
    function test_aPillGrowsIntoAChip_data() {
        return [
            { tag: "at rest", role: "occupied", expanded: false, size: { width: 8, height: 4 } },
            { tag: "shown at rest", role: "shown", expanded: false, size: { width: 16, height: 4 } },
            { tag: "chip", role: "empty", expanded: true, size: { width: 23, height: 16 } },
            { tag: "shown chip", role: "shown", expanded: true, size: { width: 39, height: 16 } }
        ];
    }

    function test_aPillGrowsIntoAChip(data) {
        compare(CapsulePills.size(data.role, data.expanded, { pillDepth: 4, chipDepth: 16, labelLength: 7 }),
            data.size);
    }
}
