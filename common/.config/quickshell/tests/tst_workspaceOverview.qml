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

    function listed(groups) {
        return groups.map(group => [group.name, group.workspaces]);
    }

    function test_monitorsGoInPhysicalOrderLeftToRight() {
        const groups = WorkspaceOverview.groups([philips, aoc, laptop], [], []);

        compare(groups.map(group => group.name), ["eDP-1", "DP-1", "HDMI-A-1"]);
    }

    function test_stackedMonitorsGoTopToBottom() {
        const lower = Object.assign({}, aoc, { x: 0, y: 1125 });

        compare(WorkspaceOverview.groups([lower, laptop], [], []).map(group => group.name),
            ["eDP-1", "DP-1"]);
    }

    function test_anExistingWorkspaceGoesUnderTheMonitorItIsOn() {
        const groups = WorkspaceOverview.groups([laptop, aoc], [{ id: 3, monitor: "DP-1" }], []);

        compare(listed(groups), [["eDP-1", [1, 2, 4, 5]], ["DP-1", [3]]]);
    }

    function test_anExistingWorkspaceBeatsTheRuleForIt() {
        const groups = WorkspaceOverview.groups([laptop, aoc], [{ id: 2, monitor: "eDP-1" }],
            [rule(2, "desc:AOC Q27G42XE")]);

        compare(listed(groups), [["eDP-1", [1, 2, 3, 4, 5]], ["DP-1", []]]);
    }

    function test_aWorkspaceThatDoesNotExistGoesWhereTheRulesSendIt() {
        const groups = WorkspaceOverview.groups([laptop, aoc], [],
            [1, 2, 3, 4, 5].map(id => rule(id, "desc:AOC Q27G42XE")));

        compare(listed(groups), [["eDP-1", []], ["DP-1", [1, 2, 3, 4, 5]]]);
    }

    function test_aRuleCanNameAMonitorByItsConnector() {
        const groups = WorkspaceOverview.groups([laptop, aoc], [], [rule(4, "DP-1")]);

        compare(listed(groups), [["eDP-1", [1, 2, 3, 5]], ["DP-1", [4]]]);
    }

    function test_withoutARuleTheFirstMonitorClaimingAWorkspaceGetsIt() {
        const groups = WorkspaceOverview.groups([aoc, laptop], [], []);

        compare(listed(groups), [["eDP-1", [1, 2, 3, 4, 5]], ["DP-1", []]]);
    }

    function test_aRuleForADisconnectedMonitorDoesNotApply() {
        const groups = WorkspaceOverview.groups([laptop], [],
            [1, 2, 3, 4, 5].map(id => rule(id, "desc:AOC Q27G42XE")));

        compare(listed(groups), [["eDP-1", [1, 2, 3, 4, 5]]]);
    }

    function test_rulesWithoutAMonitorOrForASpecialWorkspaceAreIgnored() {
        const groups = WorkspaceOverview.groups([laptop], [], [
            { workspaceString: "special:scratchpad", enabled: true },
            { workspaceString: "1", enabled: true }
        ]);

        compare(listed(groups), [["eDP-1", [1, 2, 3, 4, 5]]]);
    }

    function test_theAocAndTheLaptopScreenShowEachOfTheirWorkspacesOnce() {
        const groups = WorkspaceOverview.groups([laptop, aoc],
            [{ id: 1, monitor: "eDP-1" }, { id: 2, monitor: "DP-1" }],
            [1, 2, 3, 4, 5].map(id => rule(id, "desc:AOC Q27G42XE")));
        const shown = groups.reduce((ids, group) => ids.concat(group.workspaces), []);

        compare(shown.slice().sort(), [1, 2, 3, 4, 5]);
    }

    function test_anExistingWorkspaceNoMonitorClaimsStillAppearsInOrder() {
        const groups = WorkspaceOverview.groups([laptop], [{ id: 8, monitor: "eDP-1" }], []);

        compare(listed(groups), [["eDP-1", [1, 2, 3, 4, 5, 8]]]);
    }

    function test_workspacesOutside1To21DoNotAppear() {
        const wide = Object.assign({}, laptop, { workspaces: [0, 21, 22] });
        const groups = WorkspaceOverview.groups([wide],
            [{ id: -98, monitor: "eDP-1" }, { id: 30, monitor: "eDP-1" }], []);

        compare(listed(groups), [["eDP-1", [21]]]);
    }

    function test_anExistingWorkspaceOnAnUnknownMonitorFallsBackToTheOneClaimingIt() {
        const groups = WorkspaceOverview.groups([laptop], [{ id: 1, monitor: "DP-9" }], []);

        compare(listed(groups), [["eDP-1", [1, 2, 3, 4, 5]]]);
    }

    readonly property var noSpacing: ({ tile: 0, monitor: 0, header: 0 })
    readonly property var spacing: ({ tile: 10, monitor: 32, header: 30 })

    function monitorWith(width, height, count) {
        return { width: width, height: height, workspaces: new Array(count).fill(0) };
    }

    function test_tilesKeepTheirMonitorsProportions() {
        const fit = WorkspaceOverview.layout([monitorWith(200, 100, 1), monitorWith(100, 200, 1)],
            300, 100, noSpacing);

        compare(fit.tileHeight, 100);
        compare(fit.monitors.map(monitor => monitor.tileWidth), [200, 50]);
    }

    function test_workspacesWrapIntoTheRowsThatMakeThemLargest() {
        const fit = WorkspaceOverview.layout([monitorWith(200, 100, 4)], 1000, 1000, noSpacing);

        compare(fit.rows, 2);
        compare(fit.tileHeight, 250);
        compare(fit.monitors[0].columns, 2);
        compare(fit.monitors[0].tileWidth, 500);
    }

    function test_theGapsAndHeadersComeOutOfTheSpace() {
        const fit = WorkspaceOverview.layout([monitorWith(100, 100, 2)], 210, 240, spacing);

        compare(fit.rows, 1);
        compare(fit.tileHeight, 100);
        compare(fit.monitors[0].width, 210);
        compare(fit.height, 130);
    }

    function test_aFewWorkspacesStopGrowingAtTheTileLimit() {
        const fit = WorkspaceOverview.layout([monitorWith(100, 100, 1)], 1000, 1000,
            Object.assign({}, noSpacing, { maxTileHeight: 300 }));

        compare(fit.tileHeight, 300);
        compare(fit.monitors[0].tileWidth, 300);
    }

    function test_noMonitorsFitInNothing() {
        compare(WorkspaceOverview.layout([], 1000, 1000, spacing).tileHeight, 0);
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
        const fit = WorkspaceOverview.layout(data.monitors, data.area[0], data.area[1], spacing);

        verify(fit.tileHeight >= 60, "tiles stay usable, got " + fit.tileHeight);
        verify(fit.width <= data.area[0], "width " + fit.width);
        verify(fit.height <= data.area[1], "height " + fit.height);
        fit.monitors.forEach((monitor, index) => verify(
            monitor.columns * fit.rows >= data.monitors[index].workspaces.length));
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

    function test_theWorkspacesReadAcrossTheMonitors() {
        const groups = [{ workspaces: [1, 2] }, { workspaces: [] }, { workspaces: [11] }];

        compare(WorkspaceOverview.workspaceIds(groups), [1, 2, 11]);
    }

    function test_aRowCoversTheMonitorHoldingTheSelection() {
        const groups = [{ name: "eDP-1", workspaces: [1, 2] }, { name: "DP-1", workspaces: [3] }];

        compare(WorkspaceOverview.monitorHolding(groups, 3), 1);
        compare(WorkspaceOverview.monitorHolding(groups, 9), 0);
    }

    function test_aNewWorkspaceTakesTheNextNumberOnItsMonitor() {
        const groups = [{ name: "eDP-1", workspaces: [1, 2] }, { name: "DP-1", workspaces: [] }];

        compare(WorkspaceOverview.nextWorkspace(groups, "eDP-1"), 3);
    }

    function test_aNewWorkspaceSkipsNumbersAnotherMonitorHas() {
        const groups = [{ name: "eDP-1", workspaces: [1, 2] }, { name: "DP-1", workspaces: [3, 4] }];

        compare(WorkspaceOverview.nextWorkspace(groups, "eDP-1"), 5);
    }

    function test_aNewWorkspaceOnAnEmptyMonitorStartsFromTheFirstFreeNumber() {
        const groups = [{ name: "eDP-1", workspaces: [1, 2] }, { name: "DP-1", workspaces: [] }];

        compare(WorkspaceOverview.nextWorkspace(groups, "DP-1"), 3);
    }

    function test_noNewWorkspaceIsLeftAfter21() {
        const groups = [{ name: "eDP-1", workspaces: [19] }, { name: "DP-1", workspaces: [20, 21] }];

        compare(WorkspaceOverview.nextWorkspace(groups, "eDP-1"), null);
        compare(WorkspaceOverview.nextWorkspace(groups, "DP-1"), null);
    }
}
