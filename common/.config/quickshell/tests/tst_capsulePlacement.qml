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

    // The workspace pills sit inside the capsule, centred on it, just past its
    // row of bar elements: under the row of a top capsule and above the row of
    // a bottom one. Takes the bar content and the capsule.
    function test_theWorkspacePillsSitInsideTheCapsulePastItsRow_data() {
        return [
            { tag: "top", barPosition: "top", capsule: { x: 408, y: 0, width: 184, height: 38 },
                pills: { centre: 500, y: 30 } },
            { tag: "bottom", barPosition: "bottom", capsule: { x: 408, y: -8, width: 184, height: 38 },
                pills: { centre: 500, y: -4 } }
        ];
    }

    function test_theWorkspacePillsSitInsideTheCapsulePastItsRow(data) {
        const content = { barPosition: data.barPosition, width: 1000, height: 30 };

        compare(CapsulePlacement.workspacePills(content, data.capsule), data.pills);
    }

    // With no capsule drawn there are no pills.
    function test_noCapsuleNoWorkspacePills_data() {
        return [
            { tag: "no capsule", capsule: null },
            { tag: "empty capsule", capsule: { x: 500, y: 0, width: 0, height: 0 } }
        ];
    }

    function test_noCapsuleNoWorkspacePills(data) {
        compare(CapsulePlacement.workspacePills({ barPosition: "top", width: 1000, height: 30 }, data.capsule), null);
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
}
