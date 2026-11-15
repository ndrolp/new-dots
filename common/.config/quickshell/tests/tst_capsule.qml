import QtQuick
import QtTest
import "../components/bar/Capsule.js" as Capsule
import "../config/BarProfileModel.js" as BarProfileModel

// The capsule: which bar elements it shows while collapsed, in one row, and
// where it sits in its bar window.
TestCase {
    name: "Capsule"

    function element(id, values) {
        return Object.assign({ id: id, enabled: true }, values);
    }

    function barElements() {
        return {
            left: [element("arch"), element("systemMonitor")],
            center: [element("workspaces")],
            right: [element("notifications", { options: { badgeVisible: false } }),
                element("battery"), element("clock", { joinPrevious: true })]
        };
    }

    function shownIds(row, zone) {
        return row[zone].filter(item => item.enabled).map(item => item.id);
    }

    // A collapsed capsule shows Arch, the clock and the control center, in the
    // profile's order, as one row in the middle of the bar.
    function test_aCollapsedCapsuleShowsArchTheClockAndTheControlCenter() {
        const row = Capsule.collapsedRow(barElements(), Capsule.collapsedElementIds);

        compare(shownIds(row, "center"), ["arch", "notifications", "clock"]);
        compare(row.left, []);
        compare(row.right, []);
    }

    // The other elements are still listed, only switched off, so their options
    // and their place in the profile's order stay.
    function test_theOtherElementsAreListedSwitchedOff() {
        const row = Capsule.collapsedRow(barElements(), Capsule.collapsedElementIds);

        compare(row.center.map(item => item.id),
            ["arch", "systemMonitor", "workspaces", "notifications", "battery", "clock"]);
        compare(row.center.filter(item => !item.enabled).map(item => item.id),
            ["systemMonitor", "workspaces", "battery"]);
        compare(row.center[3].options, { badgeVisible: false });
    }

    // A disabled element stays off in the capsule too.
    function test_anElementTheProfileDisablesStaysOff() {
        const elements = barElements();
        elements.left[0].enabled = false;

        compare(shownIds(Capsule.collapsedRow(elements, Capsule.collapsedElementIds), "center"),
            ["notifications", "clock"]);
    }

    // Groups stay within the zone they were made in: the first element of a
    // zone never joins the last one of the zone before.
    function test_groupsDoNotReachAcrossTheProfilesZones() {
        const elements = barElements();
        elements.right[0].joinPrevious = true;
        const row = Capsule.collapsedRow(elements, ["arch", "notifications", "battery", "clock"]);

        compare(BarProfileModel.zoneGroups(row, "center"),
            [["arch"], ["notifications"], ["battery", "clock"]]);
    }

    function test_theCollapsedRowLeavesTheProfileAsItWas() {
        const elements = barElements();
        const before = JSON.stringify(elements);

        Capsule.collapsedRow(elements, Capsule.collapsedElementIds);
        compare(JSON.stringify(elements), before);
    }

    // The bar window draws the collapsed row on a capsule and the profile's
    // bar elements as they are on any other bar style.
    function test_onlyACapsuleDrawsTheCollapsedRow_data() {
        return [
            { tag: "capsule", barStyle: "capsule", center: ["arch", "notifications", "clock"] },
            { tag: "opaque", barStyle: "opaque", center: ["workspaces"] },
            { tag: "transparent", barStyle: "transparent", center: ["workspaces"] },
            { tag: "docked", barStyle: "docked", center: ["workspaces"] }
        ];
    }

    function test_onlyACapsuleDrawsTheCollapsedRow(data) {
        const drawn = Capsule.drawnElements({ barStyle: data.barStyle, barElements: barElements() });

        compare(shownIds(drawn, "center"), data.center);
    }

    // Expanded, the capsule shows every bar element the profile enables, in
    // its order and with its groups, except the workspaces: the workspace row
    // already shows them.
    function test_anExpandedCapsuleShowsEveryElementButTheWorkspaces() {
        const elements = barElements();
        elements.left[0].enabled = false;
        const row = Capsule.drawnElements({ barStyle: "capsule", barElements: elements, expanded: true });

        compare(shownIds(row, "center"), ["systemMonitor", "notifications", "battery", "clock"]);
        compare(BarProfileModel.zoneGroups(row, "center"),
            [["systemMonitor"], ["notifications"], ["battery", "clock"]]);
    }

    // Expanding means nothing on any other bar style.
    function test_onlyACapsuleExpands() {
        const drawn = Capsule.drawnElements({ barStyle: "opaque", barElements: barElements(), expanded: true });

        compare(shownIds(drawn, "center"), ["workspaces"]);
        compare(shownIds(drawn, "left"), ["arch", "systemMonitor"]);
    }

    // Any one cause holds the capsule expanded: hovering it, and the causes
    // later tickets add (SUPER+I, a popup inside, a change being shown).
    function test_anyCauseHoldsTheCapsuleExpanded_data() {
        return [
            { tag: "none", causes: {}, expanded: false },
            { tag: "all off", causes: { hover: false, toggled: false }, expanded: false },
            { tag: "hover", causes: { hover: true }, expanded: true },
            { tag: "another", causes: { hover: false, popupInside: true }, expanded: true }
        ];
    }

    function test_anyCauseHoldsTheCapsuleExpanded(data) {
        compare(Capsule.expanded(data.causes), data.expanded);
    }

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
        compare(Capsule.contains(data.place, data.point), data.inside);
    }

    // A collapsed capsule shows the bar elements its profile chose, in the
    // profile's order rather than the order they were chosen in.
    function test_aCollapsedCapsuleShowsTheChosenElementsInTheProfilesOrder() {
        const drawn = Capsule.drawnElements({ barStyle: "capsule", barElements: barElements(),
            capsuleElements: ["clock", "battery", "workspaces"] });

        compare(shownIds(drawn, "center"), ["workspaces", "battery", "clock"]);
    }

    // While collapsed the capsule also draws the live bar elements, the
    // recording indicator and media, which show only while they are active.
    // In the default order they sit between Arch and the clock.
    function test_aCollapsedCapsuleDrawsTheLiveElementsBetweenArchAndTheClock() {
        const drawn = Capsule.drawnElements({
            barStyle: "capsule",
            barElements: BarProfileModel.defaultProfile.barElements
        });

        compare(shownIds(drawn, "center"), ["arch", "notifications", "recording", "media", "clock"]);
    }

    // Media has something to show on a bar while any player exists, but on a
    // capsule only while a track plays: a paused player leaves it.
    function test_mediaShowsOnACapsuleOnlyWhileATrackPlays_data() {
        const playing = { isPlaying: true };
        const paused = { isPlaying: false };
        return [
            { tag: "capsule, playing", barStyle: "capsule", player: playing, shown: true },
            { tag: "capsule, paused", barStyle: "capsule", player: paused, shown: false },
            { tag: "capsule, no player", barStyle: "capsule", player: null, shown: false },
            { tag: "opaque, playing", barStyle: "opaque", player: playing, shown: true },
            { tag: "opaque, paused", barStyle: "opaque", player: paused, shown: true },
            { tag: "docked, no player", barStyle: "docked", player: null, shown: false }
        ];
    }

    function test_mediaShowsOnACapsuleOnlyWhileATrackPlays(data) {
        compare(Capsule.hasMedia(data.barStyle, data.player), data.shown);
    }

    // Expanded, the capsule shows media as the bar does: while any player
    // exists, playing or not.
    function test_anExpandedCapsuleShowsMediaWhileAnyPlayerExists_data() {
        return [
            { tag: "playing", player: { isPlaying: true }, shown: true },
            { tag: "paused", player: { isPlaying: false }, shown: true },
            { tag: "no player", player: null, shown: false }
        ];
    }

    function test_anExpandedCapsuleShowsMediaWhileAnyPlayerExists(data) {
        compare(Capsule.hasMedia("capsule", data.player, true), data.shown);
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

        compare(Capsule.surface(content, { start: 420, end: 580 }, 12),
            { x: 408, y: 0, width: 184, height: 30, radius: 15 });
    }

    // With nothing in its row there is no capsule to draw.
    function test_anEmptyRowHasNoCapsule() {
        compare(Capsule.surface({ barPosition: "top", width: 1000, height: 30 }, { start: 500, end: 500 }, 12),
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
        compare(Capsule.inputRegion(data.surface, data.margins), data.region);
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

        compare(Capsule.workspaceRow(bar, data.capsule), data.place);
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

        compare(Capsule.workspaceRow(bar, data.capsule), null);
    }
}
