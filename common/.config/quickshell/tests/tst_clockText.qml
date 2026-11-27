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

    // With the clock's 12-hour option on, the time takes AM/PM and no
    // leading zero.
    function test_twelveHourTime_data() {
        return [
            { tag: "afternoon", date: new Date(2026, 10, 26, 14, 32), time: "2:32 PM" },
            { tag: "just after midnight", date: new Date(2026, 10, 26, 0, 5), time: "12:05 AM" },
            { tag: "just after noon", date: new Date(2026, 10, 26, 12, 5), time: "12:05 PM" },
            { tag: "morning", date: new Date(2026, 10, 26, 9, 7), time: "9:07 AM" },
            { tag: "last minute", date: new Date(2026, 10, 26, 23, 59), time: "11:59 PM" }
        ];
    }

    function test_twelveHourTime(data) {
        compare(ClockText.clockText({ barStyle: "opaque" }, data.date, true),
            { date: "", time: data.time });
    }

    // The expanded capsule's date comes before the 12-hour time.
    function test_theExpandedCapsulesDateBeforeTheTwelveHourTime() {
        compare(ClockText.clockText({ barStyle: "capsule", capsuleExpanded: true,
            capsuleRowExpanded: true }, thursday, true), { date: "Thu 26 Nov · ", time: "2:32 PM" });
    }

    // Off, the time stays 24-hour.
    function test_offTheTimeStaysTwentyFourHour() {
        compare(ClockText.clockText({ barStyle: "opaque" }, thursday, false), { date: "", time: "14:32" });
    }
}
