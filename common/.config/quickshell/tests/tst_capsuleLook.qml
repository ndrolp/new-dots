import QtQuick
import QtTest
import "../components/bar/CapsuleLook.js" as CapsuleLook

// How the capsule looks expanded: more solid, and its clock with the date.
TestCase {
    name: "CapsuleLook"

    // Thursday 26 November 2026, 14:32.
    readonly property var thursday: new Date(2026, 10, 26, 14, 32, 5)

    // The capsule whose row shows its expanded view: its clock shows the date
    // before the time.
    function test_theExpandedCapsulesClockShowsTheDate() {
        compare(CapsuleLook.clockText({ barStyle: "capsule", capsuleExpanded: true,
            capsuleRowExpanded: true }, thursday), { date: "Thu 26 Nov · ", time: "14:32" });
    }

    // At rest, while held expanded but its row isn't (a popup inside sets the
    // row at rest, a change shows instead of it), and on every other bar
    // style, only the time.
    function test_otherwiseTheClockShowsOnlyTheTime_data() {
        return [
            { tag: "capsule at rest", bar: { barStyle: "capsule", capsuleExpanded: false,
                capsuleRowExpanded: false } },
            { tag: "held expanded, its row at rest or a change",
                bar: { barStyle: "capsule", capsuleExpanded: true, capsuleRowExpanded: false } },
            { tag: "opaque", bar: { barStyle: "opaque", capsuleExpanded: true, capsuleRowExpanded: true } },
            { tag: "transparent", bar: { barStyle: "transparent" } },
            { tag: "docked", bar: { barStyle: "docked" } }
        ];
    }

    function test_otherwiseTheClockShowsOnlyTheTime(data) {
        compare(CapsuleLook.clockText(data.bar, thursday), { date: "", time: "14:32" });
    }

    // A single-digit day has no leading zero; the time keeps its own.
    function test_anEarlyDayAndHour() {
        compare(CapsuleLook.clockText({ barStyle: "capsule", capsuleRowExpanded: true },
            new Date(2026, 0, 5, 9, 7)),
            { date: "Mon 5 Jan · ", time: "09:07" });
    }

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
