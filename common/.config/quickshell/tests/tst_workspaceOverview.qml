import QtQuick
import QtTest
import "../components/panels/WorkspaceOverview.js" as WorkspaceOverview

// What the workspace overview lists and how it fits on one screen: every
// monitor's workspaces, each one once, in physical order, with no scrolling.
// WorkspaceOverview.qml itself is a Quickshell window and isn't tested here.
TestCase {
    name: "WorkspaceOverview"

    readonly property var aoc: ({
        name: "DP-1", description: "AOC Q27G42XE", x: 1920, y: 0,
        width: 2560, height: 1440, workspaces: [1, 2, 3, 4, 5]
    })
    readonly property var laptop: ({
        name: "eDP-1", description: "Samsung Display", x: 0, y: 0,
        width: 1800, height: 1125, workspaces: [1, 2, 3, 4, 5]
    })
    readonly property var philips: ({
        name: "HDMI-A-1", description: "Philips PHL", x: 4480, y: 0,
        width: 1080, height: 1920, workspaces: [11, 12, 13]
    })

    function rule(id, monitor) {
        return { workspaceString: String(id), enabled: true, monitor: monitor };
    }

    function listed(monitors) {
        return monitors.map(monitor => [monitor.name, monitor.workspaces]);
    }

    function test_monitorsGoInPhysicalOrderLeftToRight() {
        const monitors = WorkspaceOverview.monitorsWithWorkspaces([philips, aoc, laptop], [], []);

        compare(monitors.map(monitor => monitor.name), ["eDP-1", "DP-1", "HDMI-A-1"]);
    }

    function test_stackedMonitorsGoTopToBottom() {
        const lower = Object.assign({}, aoc, { x: 0, y: 1125 });

        compare(WorkspaceOverview.monitorsWithWorkspaces([lower, laptop], [], []).map(monitor => monitor.name),
            ["eDP-1", "DP-1"]);
    }

    function test_anExistingWorkspaceGoesUnderTheMonitorItIsOn() {
        const monitors = WorkspaceOverview.monitorsWithWorkspaces([laptop, aoc], [{ id: 3, monitor: "DP-1" }], []);

        compare(listed(monitors), [["eDP-1", [1, 2, 4, 5]], ["DP-1", [3]]]);
    }

    function test_anExistingWorkspaceBeatsTheRuleForIt() {
        const monitors = WorkspaceOverview.monitorsWithWorkspaces([laptop, aoc], [{ id: 2, monitor: "eDP-1" }],
            [rule(2, "desc:AOC Q27G42XE")]);

        compare(listed(monitors), [["eDP-1", [1, 2, 3, 4, 5]], ["DP-1", []]]);
    }

    function test_aWorkspaceThatDoesNotExistGoesWhereTheRulesSendIt() {
        const monitors = WorkspaceOverview.monitorsWithWorkspaces([laptop, aoc], [],
            [1, 2, 3, 4, 5].map(id => rule(id, "desc:AOC Q27G42XE")));

        compare(listed(monitors), [["eDP-1", []], ["DP-1", [1, 2, 3, 4, 5]]]);
    }

    function test_aRuleCanNameAMonitorByItsConnector() {
        const monitors = WorkspaceOverview.monitorsWithWorkspaces([laptop, aoc], [], [rule(4, "DP-1")]);

        compare(listed(monitors), [["eDP-1", [1, 2, 3, 5]], ["DP-1", [4]]]);
    }

    function test_withoutARuleTheFirstMonitorClaimingAWorkspaceGetsIt() {
        const monitors = WorkspaceOverview.monitorsWithWorkspaces([aoc, laptop], [], []);

        compare(listed(monitors), [["eDP-1", [1, 2, 3, 4, 5]], ["DP-1", []]]);
    }

    function test_aRuleForADisconnectedMonitorDoesNotApply() {
        const monitors = WorkspaceOverview.monitorsWithWorkspaces([laptop], [],
            [1, 2, 3, 4, 5].map(id => rule(id, "desc:AOC Q27G42XE")));

        compare(listed(monitors), [["eDP-1", [1, 2, 3, 4, 5]]]);
    }

    function test_rulesWithoutAMonitorOrForASpecialWorkspaceAreIgnored() {
        const monitors = WorkspaceOverview.monitorsWithWorkspaces([laptop], [], [
            { workspaceString: "special:scratchpad", enabled: true },
            { workspaceString: "1", enabled: true }
        ]);

        compare(listed(monitors), [["eDP-1", [1, 2, 3, 4, 5]]]);
    }

    function test_theAocAndTheLaptopScreenShowEachOfTheirWorkspacesOnce() {
        const monitors = WorkspaceOverview.monitorsWithWorkspaces([laptop, aoc],
            [{ id: 1, monitor: "eDP-1" }, { id: 2, monitor: "DP-1" }],
            [1, 2, 3, 4, 5].map(id => rule(id, "desc:AOC Q27G42XE")));
        const shown = monitors.reduce((ids, monitor) => ids.concat(monitor.workspaces), []);

        compare(shown.slice().sort(), [1, 2, 3, 4, 5]);
    }

    function test_anExistingWorkspaceNoMonitorClaimsStillAppearsInOrder() {
        const monitors = WorkspaceOverview.monitorsWithWorkspaces([laptop], [{ id: 8, monitor: "eDP-1" }], []);

        compare(listed(monitors), [["eDP-1", [1, 2, 3, 4, 5, 8]]]);
    }

    function test_workspacesOutside1To21DoNotAppear() {
        const wide = Object.assign({}, laptop, { workspaces: [0, 21, 22] });
        const monitors = WorkspaceOverview.monitorsWithWorkspaces([wide],
            [{ id: -98, monitor: "eDP-1" }, { id: 30, monitor: "eDP-1" }], []);

        compare(listed(monitors), [["eDP-1", [21]]]);
    }

    function test_anExistingWorkspaceOnAnUnknownMonitorFallsBackToTheOneClaimingIt() {
        const monitors = WorkspaceOverview.monitorsWithWorkspaces([laptop], [{ id: 1, monitor: "DP-9" }], []);

        compare(listed(monitors), [["eDP-1", [1, 2, 3, 4, 5]]]);
    }

    readonly property var noSpacing: ({ miniature: 0, monitor: 0, header: 0 })
    readonly property var spacing: ({ miniature: 10, monitor: 32, header: 30 })

    function monitorWith(width, height, count) {
        return { width: width, height: height, workspaces: new Array(count).fill(0) };
    }

    function test_miniaturesKeepTheirMonitorsProportions() {
        const arrangement = WorkspaceOverview.layout([monitorWith(200, 100, 1), monitorWith(100, 200, 1)],
            300, 100, noSpacing, Infinity);

        compare(arrangement.miniatureHeight, 100);
        compare(arrangement.monitors.map(monitor => monitor.miniatureWidth), [200, 50]);
    }

    function test_workspacesWrapIntoTheRowsThatMakeThemLargest() {
        const arrangement = WorkspaceOverview.layout([monitorWith(200, 100, 4)], 1000, 1000, noSpacing, Infinity);

        compare(arrangement.rows, 2);
        compare(arrangement.miniatureHeight, 250);
        compare(arrangement.monitors[0].columns, 2);
        compare(arrangement.monitors[0].miniatureWidth, 500);
    }

    function test_theGapsAndHeadersComeOutOfTheSpace() {
        const arrangement = WorkspaceOverview.layout([monitorWith(100, 100, 2)], 210, 240, spacing, Infinity);

        compare(arrangement.rows, 1);
        compare(arrangement.miniatureHeight, 100);
        compare(arrangement.monitors[0].width, 210);
        compare(arrangement.height, 130);
    }

    function test_aFewWorkspacesStopGrowingAtTheLimit() {
        const arrangement = WorkspaceOverview.layout([monitorWith(100, 100, 1)], 1000, 1000,
            noSpacing, 300);

        compare(arrangement.miniatureHeight, 300);
        compare(arrangement.monitors[0].miniatureWidth, 300);
    }

    function offering(count, newWorkspace) {
        return Object.assign(monitorWith(200, 100, count), { newWorkspace: newWorkspace });
    }

    // Laid out like the four workspaces in the test above, not like three.
    function test_theNewWorkspaceSlotTakesItsPlaceLikeAMiniature() {
        const arrangement = WorkspaceOverview.layout([offering(3, 4)], 1000, 1000, noSpacing, Infinity);

        compare(arrangement.rows, 2);
        compare(arrangement.miniatureHeight, 250);
        compare(arrangement.monitors[0].columns, 2);
        compare(arrangement.monitors[0].monitor.newWorkspace, 4);
    }

    function test_noSlotIsMadeRoomForWithNoNumberLeft() {
        const arrangement = WorkspaceOverview.layout([offering(1, null)], 1000, 1000, noSpacing, Infinity);

        compare(arrangement.rows, 1);
        compare(arrangement.monitors[0].columns, 1);
        compare(arrangement.monitors[0].miniatureWidth, 1000);
    }

    function test_aMonitorWithNoWorkspacesStillHasRoomForTheSlot() {
        const arrangement = WorkspaceOverview.layout([offering(0, 1)], 400, 100, noSpacing, Infinity);

        compare(arrangement.monitors[0].columns, 1);
        compare(arrangement.monitors[0].width, 200);
    }

    function test_aPlacedMonitorIsTheOneGiven() {
        const monitor = offering(1, 2);

        compare(WorkspaceOverview.layout([monitor], 400, 100, noSpacing, Infinity).monitors[0].monitor,
            monitor);
    }

    function test_noMonitorsFitInNothing() {
        compare(WorkspaceOverview.layout([], 1000, 1000, spacing, Infinity).miniatureHeight, 0);
    }

    function test_theMostWorkspacesFitWithoutScrolling_data() {
        const aoc = (count) => monitorWith(2560, 1440, count);
        const laptop = (count) => monitorWith(1800, 1125, count);
        const philips = (count) => monitorWith(1080, 1920, count);

        return [
            { tag: "one monitor on the laptop screen", area: [1800, 1125],
                monitors: [laptop(21)] },
            { tag: "two monitors on the laptop screen", area: [1800, 1125],
                monitors: [laptop(1), aoc(20)] },
            { tag: "three monitors on the AOC", area: [2560, 1440],
                monitors: [laptop(1), aoc(10), philips(10)] },
            { tag: "three monitors on the portrait Philips", area: [1080, 1920],
                monitors: [laptop(1), aoc(10), philips(10)] }
        ];
    }

    function test_theMostWorkspacesFitWithoutScrolling(data) {
        const arrangement = WorkspaceOverview.layout(data.monitors, data.area[0], data.area[1], spacing, Infinity);

        verify(arrangement.miniatureHeight >= 60, "miniatures stay usable, got " + arrangement.miniatureHeight);
        verify(arrangement.width <= data.area[0], "width " + arrangement.width);
        verify(arrangement.height <= data.area[1], "height " + arrangement.height);
        arrangement.monitors.forEach((monitor, index) => verify(
            monitor.columns * arrangement.rows >= data.monitors[index].workspaces.length));
    }

    function test_selectionWalksAlongTheListAndWrapsAround_data() {
        return [
            { tag: "forward", selected: 2, offset: 1, expected: 3 },
            { tag: "forward past the end", selected: 12, offset: 1, expected: 1 },
            { tag: "back past the start", selected: 1, offset: -1, expected: 12 },
            { tag: "a row down past the end", selected: 11, offset: 3, expected: 2 },
            { tag: "a row longer than the list", selected: 1, offset: -9, expected: 2 },
            { tag: "from a workspace not listed", selected: 7, offset: 1, expected: 2 }
        ];
    }

    function test_selectionWalksAlongTheListAndWrapsAround(data) {
        compare(WorkspaceOverview.stepped([1, 2, 3, 11, 12], data.selected, data.offset),
            data.expected);
    }

    function test_selectionStaysPutWithNothingListed() {
        compare(WorkspaceOverview.stepped([], 4, 1), 4);
    }

    readonly property var placed: [
        { monitor: { workspaces: [1, 2, 3, 4] }, columns: 2 },
        { monitor: { workspaces: [] }, columns: 1 },
        { monitor: { workspaces: [11] }, columns: 1 }
    ]

    function test_keysMoveTheSelection_data() {
        return [
            { tag: "next crosses monitors", action: "next", selected: 4, expected: 11 },
            { tag: "previous wraps around", action: "previous", selected: 1, expected: 11 },
            { tag: "a row down stays on the monitor", action: "rowDown", selected: 1, expected: 3 },
            { tag: "a row up wraps on the monitor", action: "rowUp", selected: 1, expected: 3 },
            { tag: "a row on a lone workspace", action: "rowDown", selected: 11, expected: 11 },
            { tag: "first", action: "first", selected: 3, expected: 1 },
            { tag: "last", action: "last", selected: 3, expected: 11 }
        ];
    }

    function test_keysMoveTheSelection(data) {
        compare(WorkspaceOverview.selectionAfter(data.action, placed, data.selected), data.expected);
    }

    function test_withNothingListedThereIsNoSelectionToMove() {
        compare(WorkspaceOverview.selectionAfter("first", [], 4), -1);
        compare(WorkspaceOverview.selectionAfter("last", [], 4), -1);
        compare(WorkspaceOverview.selectionAfter("next", [], 4), 4);
        compare(WorkspaceOverview.selectionAfter("rowDown", [], 4), 4);
    }

    function test_theWorkspacesReadAcrossTheMonitors() {
        const monitors = [{ workspaces: [1, 2] }, { workspaces: [] }, { workspaces: [11] }];

        compare(WorkspaceOverview.workspaceIds(monitors), [1, 2, 11]);
    }

    function test_aRowCoversTheMonitorHoldingTheSelection() {
        const monitors = [{ name: "eDP-1", workspaces: [1, 2] }, { name: "DP-1", workspaces: [3] }];

        compare(WorkspaceOverview.monitorHolding(monitors, 3), 1);
        compare(WorkspaceOverview.monitorHolding(monitors, 9), 0);
    }

    function test_aNewWorkspaceTakesTheNextNumberOnItsMonitor() {
        const monitors = [{ name: "eDP-1", workspaces: [1, 2] }, { name: "DP-1", workspaces: [] }];

        compare(WorkspaceOverview.nextWorkspace(monitors, "eDP-1", {}), 3);
    }

    function test_aNewWorkspaceSkipsNumbersAnotherMonitorHas() {
        const monitors = [{ name: "eDP-1", workspaces: [1, 2] }, { name: "DP-1", workspaces: [3, 4] }];

        compare(WorkspaceOverview.nextWorkspace(monitors, "eDP-1", {}), 5);
    }

    function test_aNewWorkspaceOnAnEmptyMonitorStartsFromTheFirstFreeNumber() {
        const monitors = [{ name: "eDP-1", workspaces: [1, 2] }, { name: "DP-1", workspaces: [] }];

        compare(WorkspaceOverview.nextWorkspace(monitors, "DP-1", {}), 3);
    }

    function test_noNewWorkspaceIsLeftAfter21() {
        const monitors = [{ name: "eDP-1", workspaces: [19] }, { name: "DP-1", workspaces: [20, 21] }];

        compare(WorkspaceOverview.nextWorkspace(monitors, "eDP-1", {}), null);
        compare(WorkspaceOverview.nextWorkspace(monitors, "DP-1", {}), null);
    }

    function newNumbers(monitors) {
        return monitors.map(monitor => [monitor.name, monitor.newWorkspace]);
    }

    function test_eachMonitorIsOfferedTheNextNumberAfterItsLast() {
        const monitors = WorkspaceOverview.monitorsWithWorkspaces([laptop, aoc, philips], [], []);

        compare(newNumbers(monitors), [["eDP-1", 6], ["DP-1", 6], ["HDMI-A-1", 14]]);
    }

    function test_aNumberAnotherMonitorHasIsNotOffered() {
        const left = Object.assign({}, laptop, { workspaces: [1, 2] });
        const right = Object.assign({}, aoc, { workspaces: [3, 4] });

        compare(newNumbers(WorkspaceOverview.monitorsWithWorkspaces([left, right], [], [])),
            [["eDP-1", 5], ["DP-1", 5]]);
    }

    function test_aMonitorIsOfferedNothingOnceNoNumberIsLeft() {
        const left = Object.assign({}, laptop, { workspaces: [1, 2] });
        const right = Object.assign({}, aoc, { workspaces: [20, 21] });

        compare(newNumbers(WorkspaceOverview.monitorsWithWorkspaces([left, right], [], [])),
            [["eDP-1", 3], ["DP-1", null]]);
    }

    function ruledRange(first, last, monitor) {
        const rules = [];

        for (let id = first; id <= last; id++)
            rules.push(rule(id, monitor));

        return rules;
    }

    // The real rules on the real monitors: 1-10 on the AOC, 11-20 on the Philips.
    function test_aNumberTheRulesBindToAnotherMonitorIsNotOffered() {
        const full = Object.assign({}, aoc, { workspaces: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10] });
        const rules = ruledRange(1, 10, "desc:AOC Q27G42XE")
            .concat(ruledRange(11, 20, "desc:Philips PHL"));

        compare(newNumbers(WorkspaceOverview.monitorsWithWorkspaces([full, philips], [], rules)),
            [["DP-1", 21], ["HDMI-A-1", 14]]);
    }

    function test_aNumberTheRulesBindToThisMonitorIsStillOffered() {
        const rules = ruledRange(11, 20, "desc:Philips PHL");

        compare(newNumbers(WorkspaceOverview.monitorsWithWorkspaces([philips], [], rules)), [["HDMI-A-1", 14]]);
    }

    function test_aRuleForADisconnectedMonitorDoesNotHoldANumberBack() {
        const rules = ruledRange(11, 20, "desc:Philips PHL");
        const full = Object.assign({}, aoc, { workspaces: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10] });

        compare(newNumbers(WorkspaceOverview.monitorsWithWorkspaces([full], [], rules)), [["DP-1", 11]]);
    }

    function test_aMonitorIsOfferedNothingWhenTheRulesHoldEveryNumberLeft() {
        const empty = Object.assign({}, laptop, { workspaces: [] });
        const emptyPhilips = Object.assign({}, philips, { workspaces: [] });
        const last = Object.assign({}, aoc, { workspaces: [20, 21] });
        const rules = ruledRange(1, 19, "desc:Philips PHL");

        compare(newNumbers(WorkspaceOverview.monitorsWithWorkspaces([empty, last, emptyPhilips], [], rules)),
            [["eDP-1", null], ["DP-1", null], ["HDMI-A-1", 1]]);
    }

    // A window from a real `hyprctl clients -j` on the laptop at scale 1.6: its
    // mode is 2880x1800, but Hyprland gives window geometry in logical pixels.
    function test_aWindowKeepsItsPlaceOnAScaledMonitor() {
        const window = { at: [17, 52], size: [1766, 1061] };

        compare(WorkspaceOverview.windowBox(window, laptop, { width: 900, height: 562.5 }),
            { x: 8.5, y: 26, width: 883, height: 530.5 });
    }

    function test_aWindowIsPlacedFromItsOwnMonitorsCorner() {
        const window = { at: [2020, 40], size: [1280, 720] };

        compare(WorkspaceOverview.windowBox(window, aoc, { width: 256, height: 144 }),
            { x: 10, y: 4, width: 128, height: 72 });
    }

    function test_aWindowOnARotatedMonitorKeepsItsPlaceInThePortraitMiniature() {
        const window = { at: [4490, 10], size: [1060, 950] };

        compare(WorkspaceOverview.windowBox(window, philips, { width: 135, height: 240 }),
            { x: 1.25, y: 1.25, width: 132.5, height: 118.75 });
    }

    function windowOn(workspace, details) {
        return Object.assign({
            workspace: { id: workspace }, floating: false, fullscreen: 0,
            pinned: false, hidden: false, grouped: []
        }, details);
    }

    function test_aDraggedWindowKeepsItsProportions() {
        compare(WorkspaceOverview.ghostSize({ size: [1600, 900] }, 160), { width: 160, height: 90 });
        compare(WorkspaceOverview.ghostSize({ size: [900, 1800] }, 160), { width: 80, height: 160 });
    }

    function test_aWindowWithNoSizeYetDragsSquare() {
        compare(WorkspaceOverview.ghostSize({}, 160), { width: 160, height: 160 });
    }

    function test_aPinnedWindowCantBeDragged() {
        verify(WorkspaceOverview.canDrag(windowOn(2)));
        verify(WorkspaceOverview.canDrag(windowOn(2, { floating: true })));
        verify(!WorkspaceOverview.canDrag(windowOn(2, { floating: true, pinned: true })));
    }

    function test_aWindowMovesToAnotherWorkspaceButNotItsOwn() {
        verify(WorkspaceOverview.movesTo(windowOn(2), 3));
        verify(!WorkspaceOverview.movesTo(windowOn(2), 2));
    }

    function test_aWindowDoesNotMoveOutsideTheWorkspacesListed() {
        verify(WorkspaceOverview.movesTo(windowOn(2), 21));
        verify(!WorkspaceOverview.movesTo(windowOn(2), 22));
        verify(!WorkspaceOverview.movesTo(windowOn(2), 0));
    }

    function test_keysKeepTheirMeaningOutsideADrag_data() {
        return [
            { tag: "right", key: Qt.Key_Right, action: "next" },
            { tag: "left", key: Qt.Key_Left, action: "previous" },
            { tag: "down", key: Qt.Key_Down, action: "rowDown" },
            { tag: "up", key: Qt.Key_Up, action: "rowUp" },
            { tag: "home", key: Qt.Key_Home, action: "first" },
            { tag: "end", key: Qt.Key_End, action: "last" },
            { tag: "n", key: Qt.Key_N, action: "create" },
            { tag: "plus", key: Qt.Key_Plus, action: "create" },
            { tag: "return", key: Qt.Key_Return, action: "activate" },
            { tag: "enter", key: Qt.Key_Enter, action: "activate" },
            { tag: "space", key: Qt.Key_Space, action: "activate" },
            { tag: "escape", key: Qt.Key_Escape, action: "close" },
            { tag: "any other", key: Qt.Key_A, action: null }
        ];
    }

    function test_keysKeepTheirMeaningOutsideADrag(data) {
        compare(WorkspaceOverview.keyAction(data.key, false), data.action);
    }

    function test_keysThatWouldEndTheViewWaitForTheDragToEnd_data() {
        return [
            { tag: "n", key: Qt.Key_N },
            { tag: "plus", key: Qt.Key_Plus },
            { tag: "return", key: Qt.Key_Return },
            { tag: "enter", key: Qt.Key_Enter },
            { tag: "space", key: Qt.Key_Space }
        ];
    }

    function test_keysThatWouldEndTheViewWaitForTheDragToEnd(data) {
        compare(WorkspaceOverview.keyAction(data.key, true), null);
    }

    function test_escapeDuringADragCancelsOnlyTheDrag() {
        compare(WorkspaceOverview.keyAction(Qt.Key_Escape, true), "cancelDrag");
    }

    function test_aMonitorHasASlotOnlyWhileANumberIsLeft() {
        verify(WorkspaceOverview.hasSlot({ newWorkspace: 6 }));
        verify(!WorkspaceOverview.hasSlot({ newWorkspace: null }));
    }

    function test_aWindowIsNamedByItsClassInLowerCase() {
        compare(WorkspaceOverview.appClass({ class: "Google-Chrome" }), "google-chrome");
        compare(WorkspaceOverview.appClass({ class: "", initialClass: "Kitty" }), "kitty");
        compare(WorkspaceOverview.appClass({}), "application");
    }

    function test_floatingWindowsDrawOverTiledOnesAndFullscreenOverBoth() {
        const tiled = WorkspaceOverview.stacking(windowOn(1));
        const floating = WorkspaceOverview.stacking(windowOn(1, { floating: true }));
        const fullscreen = WorkspaceOverview.stacking(windowOn(1, { fullscreen: 2, floating: true }));

        verify(tiled < floating);
        verify(floating < fullscreen);
    }
}
