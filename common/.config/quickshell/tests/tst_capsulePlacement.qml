import QtQuick
import QtTest
import "../components/bar/CapsulePlacement.js" as CapsulePlacement

// Where the capsule sits in its bar window: its surface, the part that takes
// clicks, its workspace row and how it grows round a popup inside.
TestCase {
    name: "CapsulePlacement"

    // Only the pointer over the capsule itself counts as hovering it, not
    // over the rest of its bar window (such as the workspace row).
    function test_hoveringCountsOnlyOverTheCapsule_data() {
        const place = { x: 408, y: 0, width: 184, height: 30, radius: 15 };
        return [
            { tag: "inside", place: place, point: { x: 500, y: 15 }, inside: true },
            { tag: "left end", place: place, point: { x: 408, y: 0 }, inside: true },
            { tag: "beside", place: place, point: { x: 400, y: 15 }, inside: false },
            { tag: "below", place: place, point: { x: 500, y: 31 }, inside: false },
            { tag: "no capsule", place: null, point: { x: 500, y: 15 }, inside: false }
        ];
    }

    function test_hoveringCountsOnlyOverTheCapsule(data) {
        compare(CapsulePlacement.contains(data.place, data.point), data.inside);
    }

    // The capsule wraps its row with the profile's horizontal padding at both
    // ends, as deep as the bar content, its ends fully round.
    function test_theCapsuleWrapsItsRow_data() {
        return [
            { tag: "top", barPosition: "top" },
            { tag: "bottom", barPosition: "bottom" }
        ];
    }

    function test_theCapsuleWrapsItsRow(data) {
        const content = { barPosition: data.barPosition, width: 1000, height: 30 };

        compare(CapsulePlacement.surface(content, { start: 420, end: 580 }, 12),
            { x: 408, y: 0, width: 184, height: 30, radius: 15 });
    }

    // With nothing in its row there is no capsule to draw.
    function test_anEmptyRowHasNoCapsule() {
        compare(CapsulePlacement.surface({ barPosition: "top", width: 1000, height: 30 }, { start: 500, end: 500 }, 12),
            { x: 500, y: 0, width: 0, height: 0, radius: 0 });
    }

    // Only the capsule takes clicks in its bar window: around it they reach
    // the windows below. The bar content sits inside the window's margins.
    function test_onlyTheCapsuleTakesClicks_data() {
        const surface = { x: 408, y: 0, width: 184, height: 30, radius: 15 };
        return [
            { tag: "top", surface: surface, margins: { top: 6, right: 12, bottom: 0, left: 12 },
                region: { x: 420, y: 6, width: 184, height: 30 } },
            { tag: "bottom", surface: surface, margins: { top: 0, right: 12, bottom: 6, left: 12 },
                region: { x: 420, y: 0, width: 184, height: 30 } }
        ];
    }

    function test_onlyTheCapsuleTakesClicks(data) {
        compare(CapsulePlacement.inputRegion(data.surface, data.margins), data.region);
    }

    // A capsule reaches past its row, away from its screen edge, by `strip`
    // for its workspace pills, and stays fully round.
    function test_theCapsuleHoldsItsWorkspacePills_data() {
        return [
            { tag: "top", barPosition: "top", place: { x: 408, y: 0, width: 184, height: 38, radius: 19 } },
            { tag: "bottom", barPosition: "bottom", place: { x: 408, y: -8, width: 184, height: 38, radius: 19 } }
        ];
    }

    function test_theCapsuleHoldsItsWorkspacePills(data) {
        const content = { barPosition: data.barPosition, width: 1000, height: 30 };

        compare(CapsulePlacement.surface(content, { start: 420, end: 580 }, 12, 8), data.place);
    }

    // Its vertical padding reaches past its contents on both sides: towards
    // its screen edge and past its workspace pills.
    function test_theCapsulesVerticalPaddingSurroundsItsContents_data() {
        return [
            { tag: "top", barPosition: "top", place: { x: 408, y: -5, width: 184, height: 48, radius: 24 } },
            { tag: "bottom", barPosition: "bottom", place: { x: 408, y: -13, width: 184, height: 48, radius: 24 } }
        ];
    }

    function test_theCapsulesVerticalPaddingSurroundsItsContents(data) {
        const content = { barPosition: data.barPosition, width: 1000, height: 30 };

        compare(CapsulePlacement.surface(content, { start: 420, end: 580 }, 12, 8, 5), data.place);
    }

    // A capsule's pill row: media 100 px long and recording 60 px, both 24 px
    // deep, beside 40 px of pills, 8 px apart, on a capsule centred at 500.
    function pillRowGiven(media, recording) {
        return {
            centre: 500,
            spacing: 8,
            pills: 40,
            pillDepth: 4,
            left: [{ id: "media", length: 100, depth: 24, shown: media }],
            right: [{ id: "recording", length: 60, depth: 24, shown: recording }]
        };
    }

    // Media sits left of the pills and recording right of them, the three
    // centred on the capsule, as deep as the deepest of them, just past its
    // row of bar elements: under the row of a top capsule, above a bottom one.
    // The pills are centred across it.
    function test_liveElementsSitBesideTheWorkspacePills_data() {
        return [
            { tag: "top", barPosition: "top", row: { start: 392, end: 608, depth: 24,
                pills: { x: 500, y: 40 }, elements: { media: { x: 392, y: 30 }, recording: { x: 548, y: 30 } } } },
            { tag: "bottom", barPosition: "bottom", row: { start: 392, end: 608, depth: 24,
                pills: { x: 500, y: -14 }, elements: { media: { x: 392, y: -24 }, recording: { x: 548, y: -24 } } } }
        ];
    }

    function test_liveElementsSitBesideTheWorkspacePills(data) {
        const content = { barPosition: data.barPosition, width: 1000, height: 30 };

        compare(CapsulePlacement.pillRow(content, pillRowGiven(true, true)), data.row);
    }

    // With no live element shown, the pills are centred on the capsule, just
    // past its row.
    function test_withNoLiveElementThePillsAreCentred_data() {
        return [
            { tag: "top", barPosition: "top", pills: { x: 480, y: 30 } },
            { tag: "bottom", barPosition: "bottom", pills: { x: 480, y: -4 } }
        ];
    }

    function test_withNoLiveElementThePillsAreCentred(data) {
        const content = { barPosition: data.barPosition, width: 1000, height: 30 };
        const row = CapsulePlacement.pillRow(content, pillRowGiven(false, false));

        compare(row.pills, data.pills);
        compare(row.depth, 4);
        compare({ start: row.start, end: row.end }, { start: 480, end: 520 });
    }

    // Expanded, the pills are chips, as deep as they are given: deeper than
    // the live elements, they make the row as deep as themselves; shallower,
    // they are centred across it.
    function test_theRowIsAsDeepAsTheChips_data() {
        return [
            { tag: "deeper chips", pillDepth: 30, depth: 30, pills: { x: 500, y: 30 },
                media: { x: 392, y: 33 } },
            { tag: "shallower chips", pillDepth: 16, depth: 24, pills: { x: 500, y: 34 },
                media: { x: 392, y: 30 } }
        ];
    }

    function test_theRowIsAsDeepAsTheChips(data) {
        const content = { barPosition: "top", width: 1000, height: 30 };
        const given = Object.assign(pillRowGiven(true, true), { pillDepth: data.pillDepth });
        const row = CapsulePlacement.pillRow(content, given);

        compare(row.depth, data.depth);
        compare(row.pills, data.pills);
        compare(row.elements.media, data.media);
    }

    // A live element that isn't shown takes no room: the others close up
    // round the pills, still centred, and it waits just outside its side of
    // them, to fade there.
    function test_aHiddenLiveElementTakesNoRoom() {
        const content = { barPosition: "top", width: 1000, height: 30 };
        const row = CapsulePlacement.pillRow(content, pillRowGiven(false, true));

        compare({ start: row.start, end: row.end }, { start: 446, end: 554 });
        compare(row.pills.x, 446);
        compare(row.elements.recording.x, 494);
        compare(row.elements.media.x, 338);
    }

    // The capsule reaches round its pill row where that is longer than its
    // row of bar elements; with nothing in its row it still wraps its pill
    // row, the pills and any live element they show.
    function test_theCapsuleReachesRoundItsPillRow_data() {
        return [
            { tag: "longer pill row", row: { start: 450, end: 550 }, pills: { start: 392, end: 608 },
                span: { start: 392, end: 608 } },
            { tag: "shorter pill row", row: { start: 380, end: 620 }, pills: { start: 480, end: 520 },
                span: { start: 380, end: 620 } },
            { tag: "empty row", row: { start: 500, end: 500 }, pills: { start: 392, end: 608 },
                span: { start: 392, end: 608 } },
            { tag: "empty row, only the pills", row: { start: 500, end: 500 }, pills: { start: 480, end: 520 },
                span: { start: 480, end: 520 } }
        ];
    }

    function test_theCapsuleReachesRoundItsPillRow(data) {
        compare(CapsulePlacement.span(data.row, data.pills), data.span);
    }

    // A capsule's row in its bar content: 320 px long, 32 px deep.
    readonly property var row: ({ x: 800, y: 0, width: 320, height: 32, radius: 16 })

    // Without a popup inside, the capsule is just its row.
    function test_withoutAPopupInsideTheCapsuleIsItsRow() {
        compare(CapsulePlacement.withPopup(row, null, "top"), row);
    }

    // With a popup inside it grows to the wider of the row and the popup,
    // staying centred, and as deep as both, away from its screen edge: down
    // on a top bar, up on a bottom one. Its ends stay as round.
    function test_aPopupInsideGrowsTheCapsuleRoundIt_data() {
        return [
            { tag: "wider popup, top", barPosition: "top", popup: { width: 424, height: 300 },
                place: { x: 748, y: 0, width: 424, height: 332, radius: 16 } },
            { tag: "narrower popup, top", barPosition: "top", popup: { width: 200, height: 120 },
                place: { x: 800, y: 0, width: 320, height: 152, radius: 16 } },
            { tag: "wider popup, bottom", barPosition: "bottom", popup: { width: 424, height: 300 },
                place: { x: 748, y: -300, width: 424, height: 332, radius: 16 } }
        ];
    }

    function test_aPopupInsideGrowsTheCapsuleRoundIt(data) {
        compare(CapsulePlacement.withPopup(row, data.popup, data.barPosition), data.place);
    }

    // Round a popup the capsule is a rounded rectangle, no longer a full
    // pill: its corners come down to 20 px (the popup's 8 px corners plus its
    // 12 px padding), the CapsuleSurface spring morphing them there and back.
    // A row already rounder than that keeps its own.
    function test_aPopupInsideRoundsTheCapsulesCornersLess() {
        const deep = { x: 800, y: 0, width: 320, height: 64, radius: 32 };
        const popup = { width: 424, height: 300 };

        compare(CapsulePlacement.withPopup(deep, popup, "top").radius, 20);
        compare(CapsulePlacement.withPopup(deep, null, "top").radius, 32);
        compare(CapsulePlacement.withPopup(row, popup, "top").radius, 16);
    }

    // The glance goes where a popup inside would: centred on the row, just
    // past it, away from the screen edge, under a top capsule and above a
    // bottom one; the capsule grows round it as round a popup, so the
    // pointer over its cards is over the capsule.
    function test_theGlanceGoesPastTheRow_data() {
        return [
            { tag: "top", barPosition: "top", at: { x: 810, y: 32 } },
            { tag: "bottom", barPosition: "bottom", at: { x: 810, y: -60 } }
        ];
    }

    function test_theGlanceGoesPastTheRow(data) {
        const glance = { width: 300, height: 60 };
        const grown = CapsulePlacement.withPopup(row, glance, data.barPosition);

        compare(CapsulePlacement.glancePlace(row, glance, data.barPosition), data.at);
        verify(CapsulePlacement.contains(grown, { x: data.at.x + 10, y: data.at.y + 10 }));
    }
}
