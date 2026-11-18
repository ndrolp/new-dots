import QtQuick
import QtTest
import "../components/bar/CapsuleElements.js" as CapsuleElements
import "../config/BarProfileModel.js" as BarProfileModel

// The capsule's bar elements: which ones it shows while collapsed, in one
// row, which ones expanded, and when media has something to show.
TestCase {
    name: "CapsuleElements"

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
        const row = CapsuleElements.collapsedRow(barElements(), CapsuleElements.collapsedElementIds);

        compare(shownIds(row, "center"), ["arch", "notifications", "clock"]);
        compare(row.left, []);
        compare(row.right, []);
    }

    // The other elements are still listed, only switched off, so their options
    // and their place in the profile's order stay.
    function test_theOtherElementsAreListedSwitchedOff() {
        const row = CapsuleElements.collapsedRow(barElements(), CapsuleElements.collapsedElementIds);

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

        compare(shownIds(CapsuleElements.collapsedRow(elements, CapsuleElements.collapsedElementIds), "center"),
            ["notifications", "clock"]);
    }

    // Groups stay within the zone they were made in: the first element of a
    // zone never joins the last one of the zone before.
    function test_groupsDoNotReachAcrossTheProfilesZones() {
        const elements = barElements();
        elements.right[0].joinPrevious = true;
        const row = CapsuleElements.collapsedRow(elements, ["arch", "notifications", "battery", "clock"]);

        compare(BarProfileModel.zoneGroups(row, "center"),
            [["arch"], ["notifications"], ["battery", "clock"]]);
    }

    function test_theCollapsedRowLeavesTheProfileAsItWas() {
        const elements = barElements();
        const before = JSON.stringify(elements);

        CapsuleElements.collapsedRow(elements, CapsuleElements.collapsedElementIds);
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
        const drawn = CapsuleElements.drawnElements({ barStyle: data.barStyle, barElements: barElements() });

        compare(shownIds(drawn, "center"), data.center);
    }

    // Expanded, the capsule shows every bar element the profile enables, in
    // its order and with its groups, except the workspaces: the workspace row
    // already shows them.
    function test_anExpandedCapsuleShowsEveryElementButTheWorkspaces() {
        const elements = barElements();
        elements.left[0].enabled = false;
        const row = CapsuleElements.drawnElements({ barStyle: "capsule", barElements: elements, expanded: true });

        compare(shownIds(row, "center"), ["systemMonitor", "notifications", "battery", "clock"]);
        compare(BarProfileModel.zoneGroups(row, "center"),
            [["systemMonitor"], ["notifications"], ["battery", "clock"]]);
    }

    // Expanding means nothing on any other bar style.
    function test_onlyACapsuleExpands() {
        const drawn = CapsuleElements.drawnElements({ barStyle: "opaque", barElements: barElements(), expanded: true });

        compare(shownIds(drawn, "center"), ["workspaces"]);
        compare(shownIds(drawn, "left"), ["arch", "systemMonitor"]);
    }

    // While a change shows, the capsule shows only that change: no bar
    // element, even hovered or toggled expanded. Its elements stay listed,
    // with their options, for when the change is gone.
    function test_aCapsuleShowingAChangeShowsNoBarElement_data() {
        return [
            { tag: "collapsed", expanded: false },
            { tag: "expanded", expanded: true }
        ];
    }

    function test_aCapsuleShowingAChangeShowsNoBarElement(data) {
        const drawn = CapsuleElements.drawnElements({ barStyle: "capsule", barElements: barElements(),
            expanded: data.expanded, change: true });

        compare(shownIds(drawn, "center"), []);
        compare(drawn.center.length, 6);
        compare(drawn.center[3].options, { badgeVisible: false });
    }

    // A change means nothing to the elements of any other bar style.
    function test_onlyACapsuleShowsAChange() {
        const drawn = CapsuleElements.drawnElements({ barStyle: "docked", barElements: barElements(),
            change: true });

        compare(shownIds(drawn, "left"), ["arch", "systemMonitor"]);
    }

    // A collapsed capsule shows the bar elements its profile chose, in the
    // profile's order rather than the order they were chosen in.
    function test_aCollapsedCapsuleShowsTheChosenElementsInTheProfilesOrder() {
        const drawn = CapsuleElements.drawnElements({ barStyle: "capsule", barElements: barElements(),
            capsuleElements: ["clock", "battery", "arch"] });

        compare(shownIds(drawn, "center"), ["arch", "battery", "clock"]);
    }

    // A profile chooses neither the workspaces, which the workspace row shows,
    // nor the live elements, which a collapsed capsule always draws.
    function test_onlyOtherElementsCanBeChosenForACollapsedCapsule_data() {
        return [
            { tag: "workspaces", id: "workspaces", choosable: false },
            { tag: "recording", id: "recording", choosable: false },
            { tag: "media", id: "media", choosable: false },
            { tag: "clock", id: "clock", choosable: true },
            { tag: "battery", id: "battery", choosable: true }
        ];
    }

    function test_onlyOtherElementsCanBeChosenForACollapsedCapsule(data) {
        compare(CapsuleElements.choosable(data.id), data.choosable);
    }

    // So a saved choice of the workspaces doesn't show them in the capsule
    // as well as in the workspace row.
    function test_aSavedChoiceOfTheWorkspacesIsIgnored() {
        const drawn = CapsuleElements.drawnElements({ barStyle: "capsule", barElements: barElements(),
            capsuleElements: ["workspaces", "clock"] });

        compare(shownIds(drawn, "center"), ["clock"]);
    }

    // The live elements, the recording indicator and media, are never drawn
    // in the row, collapsed or expanded: they sit beside the workspace pills
    // instead (see liveElements).
    function test_theRowNeverDrawsTheLiveElements_data() {
        return [
            { tag: "collapsed", expanded: false },
            { tag: "expanded", expanded: true }
        ];
    }

    function test_theRowNeverDrawsTheLiveElements(data) {
        const drawn = CapsuleElements.drawnElements({
            barStyle: "capsule",
            barElements: BarProfileModel.defaultProfile.barElements,
            expanded: data.expanded
        });
        const shown = shownIds(drawn, "center");

        compare(shown.indexOf("recording"), -1);
        compare(shown.indexOf("media"), -1);
        verify(shown.indexOf("clock") !== -1);
    }

    // So a collapsed capsule's row is just what its profile chose.
    function test_aCollapsedCapsulesRowIsWhatItsProfileChose() {
        const drawn = CapsuleElements.drawnElements({
            barStyle: "capsule",
            barElements: BarProfileModel.defaultProfile.barElements
        });

        compare(shownIds(drawn, "center"), ["arch", "notifications", "clock"]);
    }

    // On a capsule, media sits left of the workspace pills and the recording
    // indicator right of them, while the profile enables them.
    function test_mediaSitsLeftOfThePillsAndRecordingRight() {
        compare(CapsuleElements.liveElements({ barStyle: "capsule",
            barElements: BarProfileModel.defaultProfile.barElements }),
            { left: ["media"], right: ["recording"] });
    }

    // A live element the profile disables isn't beside the pills either.
    function test_aDisabledLiveElementIsNotBesideThePills() {
        const elements = barElements();
        elements.right.push(element("recording", { enabled: false }), element("media"));

        compare(CapsuleElements.liveElements({ barStyle: "capsule", barElements: elements }),
            { left: ["media"], right: [] });
    }

    // Live elements are a capsule's: any other bar style draws them in its
    // zones like any other bar element.
    function test_onlyACapsuleHasLiveElements_data() {
        return [
            { tag: "opaque", barStyle: "opaque" },
            { tag: "transparent", barStyle: "transparent" },
            { tag: "docked", barStyle: "docked" }
        ];
    }

    function test_onlyACapsuleHasLiveElements(data) {
        const elements = BarProfileModel.defaultProfile.barElements;

        compare(CapsuleElements.liveElements({ barStyle: data.barStyle, barElements: elements }),
            { left: [], right: [] });
        compare(CapsuleElements.drawnElements({ barStyle: data.barStyle, barElements: elements }), elements);
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
        compare(CapsuleElements.hasMedia({ barStyle: data.barStyle }, data.player), data.shown);
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
        compare(CapsuleElements.hasMedia({ barStyle: "capsule" }, data.player, true), data.shown);
    }
}
