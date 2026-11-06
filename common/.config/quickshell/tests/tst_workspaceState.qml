import QtQuick
import QtTest
import "../services/WorkspaceState.js" as WorkspaceState

// What the workspace service decides without Quickshell: which windows a
// workspace shows and what it asks Hyprland to do.
// WorkspaceService.qml itself needs Quickshell and isn't tested here.
TestCase {
    name: "WorkspaceState"

    function windowOn(workspace, details) {
        return Object.assign({
            workspace: { id: workspace }, floating: false, fullscreen: 0,
            pinned: false, hidden: false, grouped: []
        }, details);
    }

    function test_aWindowShowsOnItsOwnWorkspaceOnly() {
        const window = windowOn(2);

        verify(WorkspaceState.isShownOn(window, 2, 1));
        verify(!WorkspaceState.isShownOn(window, 3, 1));
    }

    function test_floatingAndFullscreenWindowsShowNormally() {
        verify(WorkspaceState.isShownOn(windowOn(2, { floating: true }), 2, 1));
        verify(WorkspaceState.isShownOn(windowOn(2, { fullscreen: 2 }), 2, 1));
    }

    function test_aPinnedWindowShowsOnlyOnTheWorkspaceYouAreOn() {
        const pinned = windowOn(4, { floating: true, pinned: true });

        verify(WorkspaceState.isShownOn(pinned, 4, 4));
        verify(!WorkspaceState.isShownOn(pinned, 4, 1));
    }

    function test_aScratchpadWindowIsOnNoWorkspaceListed() {
        const scratchpad = windowOn(-98, { workspace: { id: -98, name: "special:scratchpad" } });

        for (let id = 1; id <= 21; id++)
            verify(!WorkspaceState.isShownOn(scratchpad, id, id));
    }

    function test_aWindowGroupShowsOnlyItsActiveWindow() {
        const members = ["0x1", "0x2"];

        verify(WorkspaceState.isShownOn(windowOn(2, { grouped: members }), 2, 1));
        verify(!WorkspaceState.isShownOn(windowOn(2, { grouped: members, hidden: true }), 2, 1));
    }

    function test_aWindowHyprlandHasNotDescribedYetIsNotShown() {
        verify(!WorkspaceState.isShownOn({}, 2, 2));
    }

    readonly property string moveTo7:
        'hl.dsp.window.move({ workspace = 7, follow = false, window = "address:0x55ab10" })'
    readonly property string send7ToDp1: 'hl.dsp.workspace.move({ workspace = 7, monitor = "DP-1" })'

    function test_aMoveToAWorkspaceThatExistsNamesTheWindowAndDoesNotFollowIt() {
        compare(WorkspaceState.moveCommand("0x55ab10", 7, "DP-1", true),
            ["hyprctl", "dispatch", moveTo7]);
    }

    function test_aMoveAddsThePrefixHyprlandExpectsOnAnAddress() {
        compare(WorkspaceState.moveCommand("55ab10", 7, "DP-1", true),
            ["hyprctl", "dispatch", moveTo7]);
    }

    // Hyprland makes a missing workspace on the focused monitor or the one a
    // rule names, so it's sent to its monitor once the window is in it.
    function test_aMoveToAWorkspaceThatDoesNotExistThenSendsItToItsMonitor() {
        compare(WorkspaceState.moveCommand("0x55ab10", 7, "DP-1", false),
            ["hyprctl", "--batch", "dispatch " + moveTo7 + " ; dispatch " + send7ToDp1]);
    }

    function test_aMoveIsNeverBuiltFromSomethingThatIsNotAnAddress() {
        compare(WorkspaceState.moveCommand('0x1" }) hl.exec_cmd("x', 7, "DP-1", true), null);
        compare(WorkspaceState.moveCommand('0x1" })', 7, "DP-1", false), null);
    }

    function test_aMoveIsNeverBuiltFromSomethingThatIsNotAMonitor() {
        compare(WorkspaceState.moveCommand("0x55ab10", 7, 'DP-1" }) ; reload', false), null);
    }

    function test_monitorNamesHyprlandGivesAreKept_data() {
        return [
            { tag: "connector", monitor: "HDMI-A-1" },
            { tag: "laptop", monitor: "eDP-1" },
            { tag: "virtual", monitor: "HEADLESS-2" }
        ];
    }

    function test_monitorNamesHyprlandGivesAreKept(data) {
        verify(WorkspaceState.moveCommand("0x55ab10", 7, data.monitor, false) !== null);
    }

    // Focusing a missing workspace makes it on the focused monitor, which the
    // pointer may have left, so it's sent to its monitor too.
    function test_creatingAWorkspaceFocusesItThenSendsItToItsMonitor() {
        compare(WorkspaceState.createCommand(7, "DP-1"), ["hyprctl", "--batch",
            "dispatch hl.dsp.focus({ workspace = 7 }) ; dispatch " + send7ToDp1]);
    }

    function test_aWorkspaceIsNeverCreatedFromSomethingThatIsNotAMonitor() {
        compare(WorkspaceState.createCommand(7, 'DP-1" }) ; reload'), null);
    }
}
