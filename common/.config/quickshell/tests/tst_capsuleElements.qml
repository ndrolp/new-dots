import QtQuick
import QtTest
import "../components/bar/CapsuleElements.js" as CapsuleElements
import "../config/BarProfileModel.js" as BarProfileModel

// The capsule's row of bar elements: which ones it shows while collapsed,
// in one row, and which ones expanded; tst_liveElements covers the ones
// beside its pills.
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
    }

    // A hidden element isn't in the collapsed row; expanded, it shows in the
    // row like any other element.
    function test_aHiddenLiveElementOnlyShowsExpanded() {
        const bar = { barStyle: "capsule", barElements: BarProfileModel.defaultProfile.barElements,
            capsulePlaces: places({ recording: "hidden" }) };

        compare(shownIds(CapsuleElements.drawnElements(bar), "center").indexOf("recording"), -1);
        verify(shownIds(CapsuleElements.drawnElements(Object.assign({ expanded: true }, bar)), "center")
            .indexOf("recording") !== -1);
    }

    // The live elements, by default the recording indicator and media, are
    // never drawn in the row, collapsed or expanded: they sit beside the
    // workspace pills instead (see tst_liveElements).
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

        compare(shownIds(drawn, "center"), ["arch", "notifications", "clock", "pomodoro"]);
    }

    // Any other bar style draws the live-capable elements in its zones like
    // any other bar element: its profile's as they are.
    function test_anyOtherBarStyleDrawsItsProfilesElements_data() {
        return [
            { tag: "opaque", barStyle: "opaque" },
            { tag: "transparent", barStyle: "transparent" },
            { tag: "docked", barStyle: "docked" }
        ];
    }

    function test_anyOtherBarStyleDrawsItsProfilesElements(data) {
        const elements = BarProfileModel.defaultProfile.barElements;

        compare(CapsuleElements.drawnElements({ barStyle: data.barStyle, barElements: elements }), elements);
    }
}
