import QtQuick
import QtTest
import "../components/bar/CapsuleLook.js" as CapsuleLook

// How the capsule looks expanded, while its row shows its expanded view:
// more solid.
TestCase {
    name: "CapsuleLook"

    // The capsule looks expanded, solid and with the date on its clock, while
    // its row shows its expanded view, not merely while it is held expanded.
    function test_itLooksExpandedWhileItsRowIs_data() {
        return [
            { tag: "row expanded", bar: { barStyle: "capsule", capsuleExpanded: true,
                capsuleRowExpanded: true }, expected: true },
            { tag: "held expanded, row at rest", bar: { barStyle: "capsule", capsuleExpanded: true,
                capsuleRowExpanded: false }, expected: false },
            { tag: "at rest", bar: { barStyle: "capsule", capsuleRowExpanded: false }, expected: false },
            { tag: "docked", bar: { barStyle: "docked", capsuleRowExpanded: true }, expected: false }
        ];
    }

    function test_itLooksExpandedWhileItsRowIs(data) {
        compare(CapsuleLook.looksExpanded(data.bar), data.expected);
    }

    // Its fill is the profile's opacity at rest, 15 points more expanded,
    // never past fully opaque, and in between partway along the spring.
    function test_theFillsOpacity_data() {
        return [
            { tag: "at rest", alpha: 0.6, solidity: 0, expected: 0.6 },
            { tag: "expanded", alpha: 0.6, solidity: 1, expected: 0.75 },
            { tag: "halfway", alpha: 0.6, solidity: 0.5, expected: 0.675 },
            { tag: "overshooting", alpha: 0.6, solidity: 1.1, expected: 0.75 },
            { tag: "nearly opaque", alpha: 0.95, solidity: 1, expected: 1 }
        ];
    }

    function test_theFillsOpacity(data) {
        fuzzyCompare(CapsuleLook.fillAlpha(data.alpha, data.solidity), data.expected, 0.0001);
    }

    // Expanded its shadow reaches further and is darker at every ring.
    function test_theExpandedShadowIsLarger() {
        const resting = CapsuleLook.shadowRings(0);
        const expanded = CapsuleLook.shadowRings(1);

        compare(resting.filter(dark => dark > 0).length, 4);
        compare(expanded.filter(dark => dark > 0).length, 6);
        expanded.forEach((dark, index) => verify(dark > resting[index], "ring " + index));
    }
}
