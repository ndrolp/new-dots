import QtQuick
import QtTest
import "../components/bar/CapsuleElements.js" as CapsuleElements
import "../config/BarProfileModel.js" as BarProfileModel

// The capsule's bar elements: which ones it shows while collapsed, in one
// row, which ones expanded, and when media has something to show.
TestCase {
    name: "CapsuleElements"

    // The bar elements a profile shows in its collapsed row by default.
    readonly property var defaultShown: ["arch", "clock", "notifications"]

    // Collapsed places with `values` over the default ones.
    function places(values) {
        return Object.assign(BarProfileModel.completeCapsulePlaces(undefined), values);
    }

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
        const row = CapsuleElements.collapsedRow(barElements(), defaultShown);

        compare(shownIds(row, "center"), ["arch", "notifications", "clock"]);
        compare(row.left, []);
        compare(row.right, []);
    }

    // The other elements are still listed, only switched off, so their options
    // and their place in the profile's order stay.
    function test_theOtherElementsAreListedSwitchedOff() {
        const row = CapsuleElements.collapsedRow(barElements(), defaultShown);

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

        compare(shownIds(CapsuleElements.collapsedRow(elements, defaultShown), "center"),
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

        CapsuleElements.collapsedRow(elements, defaultShown);
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

    // A collapsed capsule shows the bar elements whose place is Shown, in
    // the profile's order.
    function test_aCollapsedCapsuleShowsTheShownElementsInTheProfilesOrder() {
        const drawn = CapsuleElements.drawnElements({ barStyle: "capsule", barElements: barElements(),
            capsulePlaces: places({ clock: "shown", battery: "shown", arch: "shown", notifications: "hidden" }) });

        compare(shownIds(drawn, "center"), ["arch", "battery", "clock"]);
    }

    // A saved place for the workspaces doesn't show them in the capsule as
    // well as in the workspace row.
    function test_aSavedPlaceOfTheWorkspacesIsIgnored() {
        const drawn = CapsuleElements.drawnElements({ barStyle: "capsule", barElements: barElements(),
            capsulePlaces: places({ workspaces: "shown", arch: "hidden", notifications: "hidden" }) });

        compare(shownIds(drawn, "center"), ["clock"]);
    }

    // A live element whose place is Shown is drawn in the row, collapsed or
    // expanded, and not beside the pills.
    function test_aLiveElementShownInTheRowIsDrawnThere_data() {
        return [
            { tag: "collapsed", expanded: false },
            { tag: "expanded", expanded: true }
        ];
    }

    function test_aLiveElementShownInTheRowIsDrawnThere(data) {
        const bar = { barStyle: "capsule", barElements: BarProfileModel.defaultProfile.barElements,
            capsulePlaces: places({ media: "shown" }), expanded: data.expanded };

        verify(shownIds(CapsuleElements.drawnElements(bar), "center").indexOf("media") !== -1);
        compare(CapsuleElements.liveElements(bar), { left: [], right: ["recording"] });
    }

    // A hidden element is neither in the collapsed row nor beside the pills;
    // expanded, it shows in the row like any other element.
    function test_aHiddenLiveElementOnlyShowsExpanded() {
        const bar = { barStyle: "capsule", barElements: BarProfileModel.defaultProfile.barElements,
            capsulePlaces: places({ recording: "hidden" }) };

        compare(shownIds(CapsuleElements.drawnElements(bar), "center").indexOf("recording"), -1);
        compare(CapsuleElements.liveElements(bar), { left: ["media"], right: [] });
        verify(shownIds(CapsuleElements.drawnElements(Object.assign({ expanded: true }, bar)), "center")
            .indexOf("recording") !== -1);
    }

    // Live right puts media right of the pills, after the recording
    // indicator: several on one side follow the profile's order.
    function test_liveElementsOnOneSideFollowTheProfilesOrder() {
        const elements = barElements();
        elements.left.unshift(element("media"));
        elements.right.push(element("recording"));

        compare(CapsuleElements.liveElements({ barStyle: "capsule", barElements: elements,
            capsulePlaces: places({ media: "liveRight" }) }), { left: [], right: ["media", "recording"] });
    }

    // The live elements, by default the recording indicator and media, are
    // never drawn in the row, collapsed or expanded: they sit beside the
    // workspace pills instead (see liveElements).
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

    // A live element in a group leaves it, since a group can't reach the
    // pills: the rest of the group keeps one shared background in the
    // expanded row, and joins no group before it.
    function test_aLiveElementLeavesItsGroup_data() {
        return [
            { tag: "first of its group", right: [element("media"), element("audio", { joinPrevious: true }),
                element("clock", { joinPrevious: true })], groups: [["battery"], ["audio", "clock"]] },
            { tag: "inside its group", right: [element("audio"), element("media", { joinPrevious: true }),
                element("clock", { joinPrevious: true })], groups: [["battery"], ["audio", "clock"]] },
            { tag: "last of its group", right: [element("audio"), element("clock", { joinPrevious: true }),
                element("recording", { joinPrevious: true })], groups: [["battery"], ["audio", "clock"]] },
            { tag: "alone in its group", right: [element("media"), element("clock", { joinPrevious: true })],
                groups: [["battery"], ["clock"]] },
            { tag: "both live", right: [element("media"), element("recording", { joinPrevious: true }),
                element("audio", { joinPrevious: true }), element("clock", { joinPrevious: true })],
                groups: [["battery"], ["audio", "clock"]] }
        ];
    }

    function test_aLiveElementLeavesItsGroup(data) {
        const elements = { left: [], center: [element("workspaces"), element("battery")], right: data.right };
        const drawn = CapsuleElements.drawnElements({ barStyle: "capsule", barElements: elements, expanded: true });

        compare(BarProfileModel.zoneGroups(drawn, "center"), data.groups);
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

    // A capsule profile with the given text and icon sizes; its bar elements
    // are 20 + 3 * 2 = 26 px thick.
    function sizedProfile(textSize, iconSize) {
        return { barStyle: "capsule", barHeight: 34, elementVerticalPadding: 4,
            workspaceButtonSize: 20, pillVerticalPadding: 3, textSize: textSize, iconSize: iconSize };
    }

    // A live element beside the pills is drawn at 80% of the profile's text
    // and icon sizes, in a pill 80% as thick, rounded to whole pixels.
    function test_aLiveElementIsDrawnAtEightyPercent_data() {
        return [
            { tag: "balanced", profile: sizedProfile(14, 14), sizes: { textSize: 11, iconSize: 11, thickness: 21 } },
            { tag: "compact", profile: sizedProfile(13, 13), sizes: { textSize: 10, iconSize: 10, thickness: 21 } },
            { tag: "spacious", profile: sizedProfile(15, 15), sizes: { textSize: 12, iconSize: 12, thickness: 21 } },
            { tag: "large icons", profile: sizedProfile(14, 20), sizes: { textSize: 11, iconSize: 16, thickness: 21 } }
        ];
    }

    function test_aLiveElementIsDrawnAtEightyPercent(data) {
        compare(CapsuleElements.elementSizes(data.profile, true), data.sizes);
    }

    // So applying a density preset resizes live elements in proportion.
    function test_aDensityPresetResizesLiveElements() {
        const profile = Object.assign(sizedProfile(14, 14), BarProfileModel.densityPresetChanges("spacious"));

        compare(CapsuleElements.elementSizes(profile, true), { textSize: 12, iconSize: 12, thickness: 24 });
    }

    // Any other bar element, and every one on another bar style, keeps the
    // profile's sizes.
    function test_otherElementsKeepTheProfilesSizes() {
        compare(CapsuleElements.elementSizes(sizedProfile(14, 16), false),
            { textSize: 14, iconSize: 16, thickness: 26 });
    }
}
