import QtQuick
import QtTest
import "../components/bar/ClockText.js" as ClockText

// What the clock shows: the time, and in a capsule that looks expanded the
// date before it.
TestCase {
    name: "ClockText"

    // Thursday 26 November 2026, 14:32.
    readonly property var thursday: new Date(2026, 10, 26, 14, 32, 5)

    // The capsule whose row shows its expanded view: its clock shows the date
    // before the time.
    function test_theExpandedCapsulesClockShowsTheDate() {
        compare(ClockText.clockText({ barStyle: "capsule", capsuleExpanded: true,
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
        compare(ClockText.clockText(data.bar, thursday), { date: "", time: "14:32" });
    }

    // A single-digit day has no leading zero; the time keeps its own.
    function test_anEarlyDayAndHour() {
        compare(ClockText.clockText({ barStyle: "capsule", capsuleRowExpanded: true },
            new Date(2026, 0, 5, 9, 7)),
            { date: "Mon 5 Jan · ", time: "09:07" });
    }
}
