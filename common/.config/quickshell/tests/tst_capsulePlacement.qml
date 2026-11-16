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

    // The workspace row has a window of its own on the capsule's screen edge,
    // running the length of the screen. It keeps clear of what the capsule
    // reserves, then the profile's spacing: under a top capsule and above a
    // bottom one. Its pills are centred on the capsule's centre.
    function test_theWorkspaceRowSitsPastTheCapsuleCentredWithIt_data() {
        const capsule = { x: 420, y: 6, width: 184, height: 30 };
        return [
            { tag: "top", barPosition: "top", capsule: capsule,
                place: { anchors: { top: true, right: true, bottom: false, left: true }, margin: 4, centre: 512 } },
            { tag: "bottom", barPosition: "bottom", capsule: capsule,
                place: { anchors: { top: false, right: true, bottom: true, left: true }, margin: 4, centre: 512 } }
        ];
    }

    function test_theWorkspaceRowSitsPastTheCapsuleCentredWithIt(data) {
        const bar = { barStyle: "capsule", barPosition: data.barPosition, spacing: 4 };

        compare(CapsulePlacement.workspaceRow(bar, data.capsule), data.place);
    }

    // Only a capsule has a workspace row, and only while the capsule is there.
    function test_onlyACapsuleHasAWorkspaceRow_data() {
        const capsule = { x: 420, y: 6, width: 184, height: 30 };
        return [
            { tag: "opaque", barStyle: "opaque", capsule: capsule },
            { tag: "transparent", barStyle: "transparent", capsule: capsule },
            { tag: "docked", barStyle: "docked", capsule: capsule },
            { tag: "no capsule", barStyle: "capsule", capsule: { x: 500, y: 6, width: 0, height: 0 } }
        ];
    }

    function test_onlyACapsuleHasAWorkspaceRow(data) {
        const bar = { barStyle: data.barStyle, barPosition: "top", spacing: 4 };

        compare(CapsulePlacement.workspaceRow(bar, data.capsule), null);
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
