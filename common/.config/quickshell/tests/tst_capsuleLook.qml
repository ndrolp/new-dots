import QtQuick
import QtTest
import "../components/bar/CapsuleLook.js" as CapsuleLook

// How the capsule looks expanded: more solid, and its clock with the date.
TestCase {
    name: "CapsuleLook"

    // Thursday 26 November 2026, 14:32.
    readonly property var thursday: new Date(2026, 10, 26, 14, 32, 5)

    // The expanded capsule's clock shows the date before the time.
    function test_theExpandedCapsulesClockShowsTheDate() {
        compare(CapsuleLook.clockText({ barStyle: "capsule", capsuleExpanded: true }, thursday),
            { date: "Thu 26 Nov · ", time: "14:32" });
    }

    // At rest, and on every other bar style, only the time.
    function test_otherwiseTheClockShowsOnlyTheTime_data() {
        return [
            { tag: "capsule at rest", bar: { barStyle: "capsule", capsuleExpanded: false } },
            { tag: "opaque", bar: { barStyle: "opaque", capsuleExpanded: true } },
            { tag: "transparent", bar: { barStyle: "transparent" } },
            { tag: "docked", bar: { barStyle: "docked" } }
        ];
    }

    function test_otherwiseTheClockShowsOnlyTheTime(data) {
        compare(CapsuleLook.clockText(data.bar, thursday), { date: "", time: "14:32" });
    }

    // A single-digit day has no leading zero; the time keeps its own.
    function test_anEarlyDayAndHour() {
        compare(CapsuleLook.clockText({ barStyle: "capsule", capsuleExpanded: true }, new Date(2026, 0, 5, 9, 7)),
            { date: "Mon 5 Jan · ", time: "09:07" });
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
