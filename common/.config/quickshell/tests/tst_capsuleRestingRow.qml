import QtQuick
import QtTest
import "../components/bar/BarElementItems.js" as BarElementItems
import "../components/bar/BarLayout.js" as BarLayout
import "../components/bar/BarPlacement.js" as BarPlacement
import "../components/bar/CapsuleElements.js" as CapsuleElements
import "../components/bar/CapsulePlacement.js" as CapsulePlacement
import "../components/bar/LiveElements.js" as LiveElements
import "../config/BarProfileModel.js" as BarProfileModel

// The at-rest capsule's row, laid out the way BarContent lays it out: what
// its bar elements show sits evenly apart, centred on the capsule and on its
// pill row, with equal padding at both ends, whatever mix of shown, live and
// hidden elements its profile has. What an element shows is its content: its
// glyph, or its icon and text, as long as `inks` says (measured in the
// shell's font, GeistMono Nerd Font Propo).
TestCase {
    name: "CapsuleRestingRow"

    // How long the workspace pills are along the bar.
    readonly property real pillsLength: 120
    // How long a live element is beside the pills.
    readonly property real liveLength: 40

    function element(id, values) {
        return Object.assign({ id: id, enabled: true }, values);
    }

    function profile(values) {
        return Object.assign({
            barStyle: "capsule",
            barPosition: "top",
            capsuleExpanded: false,
            spacing: 4,
            horizontalPadding: 14,
            groupHorizontalPadding: 4,
            groupVerticalPadding: 0,
            workspaceButtonSize: 18,
            pillsTransparent: true
        }, values);
    }

    // The island profile on the ultrawide: network, clock and battery
    // shown, in one group with the hidden audio before them and pomodoro,
    // recording and privacy live right between and after them.
    function island(values) {
        return profile(Object.assign({
            barElements: {
                left: [], center: [],
                right: [element("audio"), element("network", { joinPrevious: true }),
                    element("clock", { joinPrevious: true }), element("pomodoro", { joinPrevious: true }),
                    element("battery", { joinPrevious: true }), element("notifications", { joinPrevious: true }),
                    element("recording", { joinPrevious: true }), element("privacy", { joinPrevious: true }),
                    element("bluetooth", { joinPrevious: true }), element("workspaces", { joinPrevious: true }),
                    element("tray")]
            },
            capsulePlaces: {
                audio: "hidden", network: "shown", clock: "shown", battery: "shown",
                notifications: "hidden", bluetooth: "hidden", tray: "hidden",
                pomodoro: "liveRight", recording: "liveRight", privacy: "liveRight"
            }
        }, values));
    }

    // Measured: the Wi-Fi glyph at 17 px, the clock's icon, gap and "12:34"
    // at 13 px, the battery glyph at 17 px, the Bluetooth and tray glyphs at
    // 13 px.
    readonly property var inks: ({
        network: 17.5, clock: 56, battery: 8.5, bluetooth: 9, tray: 13, audio: 30, notifications: 13
    })

    // The capsule at rest as BarContent lays it out, with the live elements
    // in `liveShown` shown beside its pills: its row's `inks` { start, end }
    // in order, its `capsule` { start, end } and its `pills` { start, end }.
    function restingRow(given, liveShown) {
        const drawn = CapsuleElements.drawnElements({
            barStyle: given.barStyle, barElements: given.barElements,
            capsulePlaces: given.capsulePlaces, expanded: false
        });
        const drawnProfile = Object.assign({}, given, { barElements: drawn });
        const shown = id => BarProfileModel.elementEnabled(drawn, id) && inks[id] !== undefined;
        const lengthOf = id => BarElementItems.elementLength(id, inks[id], drawnProfile, shown);
        const bar = {
            barPosition: given.barPosition, width: 3440, height: 28, spacing: given.spacing,
            groupPadding: given.groupHorizontalPadding, groupInset: 0, endPadding: 0
        };
        const zone = BarLayout.zone(bar, BarProfileModel.zoneGroups(drawn, "center", shown), lengthOf);
        const start = BarLayout.zoneStart(bar, "center", zone.length);
        const row = { start: start, end: start + zone.length };
        const live = LiveElements.liveElements(given);
        const entry = id => ({ id: id, length: liveLength, depth: 20, shown: liveShown.indexOf(id) !== -1 });
        const pills = CapsulePlacement.pillRow(bar, {
            centre: (row.start + row.end) / 2, spacing: given.spacing, pills: pillsLength,
            left: live.left.map(entry), right: live.right.map(entry)
        });
        const surface = CapsulePlacement.surface(bar, CapsulePlacement.span(row, pills),
            BarPlacement.capsuleEndPadding(given), pills.depth + given.spacing, 0);
        const shownInks = Object.keys(zone.positions)
            .map(id => {
                const inkStart = start + zone.positions[id].start + (lengthOf(id) - inks[id]) / 2;
                return { start: inkStart, end: inkStart + inks[id] };
            })
            .sort((a, b) => a.start - b.start);

        return {
            inks: shownInks,
            capsule: { start: surface.x, end: surface.x + surface.width },
            pills: { start: pills.start, end: pills.end }
        };
    }

    function centre(span) {
        return (span.start + span.end) / 2;
    }

    function test_theRowIsEvenAndCentred_data() {
        return [
            { tag: "island, nothing live", profile: island(), live: [] },
            { tag: "island, pomodoro live", profile: island(), live: ["pomodoro"] },
            { tag: "island, every live one", profile: island(), live: ["pomodoro", "recording", "privacy"] },
            {
                tag: "live left and right, hidden between, ungrouped",
                profile: profile({
                    barElements: {
                        left: [element("media"), element("bluetooth")],
                        center: [element("audio"), element("tray")],
                        right: [element("recording"), element("clock"), element("network")]
                    },
                    capsulePlaces: {
                        media: "liveLeft", bluetooth: "shown", audio: "hidden", tray: "shown",
                        recording: "liveRight", clock: "shown", network: "shown"
                    }
                }),
                live: ["media"]
            },
            {
                tag: "grouped with pills not transparent",
                profile: island({ pillsTransparent: false }),
                live: ["recording"]
            }
        ];
    }

    function test_theRowIsEvenAndCentred(data) {
        const row = restingRow(data.profile, data.live);
        const inks = row.inks;
        verify(inks.length >= 3, "the row shows its elements");

        const gap = inks[1].start - inks[0].end;
        for (let index = 1; index < inks.length; index++)
            fuzzyCompare(inks[index].start - inks[index - 1].end, gap, 0.01,
                "gap before element " + index);

        const rowInk = { start: inks[0].start, end: inks[inks.length - 1].end };
        fuzzyCompare(rowInk.start - row.capsule.start, row.capsule.end - rowInk.end, 1,
            "padding at both ends");
        fuzzyCompare(centre(rowInk), centre(row.capsule), 0.5, "centred on the capsule");
        fuzzyCompare(centre(rowInk), centre(row.pills), 0.5, "centred on the pill row");
    }

    // An icon-only element drawing its own pill keeps it square: then the
    // pills' edges are what sits evenly apart. Only outside a capsule, which
    // draws no element pill (tst_capsuleBackground.qml).
    function test_anIconElementWithItsOwnPillStaysSquare() {
        const given = profile({
            barStyle: "transparent",
            pillsTransparent: false,
            barElements: { left: [], center: [element("network"), element("clock")], right: [] }
        });
        compare(BarElementItems.elementLength("network", 17.5, given, () => true), 18);
    }
}
