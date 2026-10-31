import QtQuick
import QtTest
import "../modules/OpenPopup.js" as OpenPopup

// At most one popup is open, on one bar: clicking its bar element again
// closes it, and clicking another opens that one instead.
TestCase {
    name: "OpenPopup"

    readonly property var leftBar: ({ name: "left" })
    readonly property var rightBar: ({ name: "right" })

    function test_noPopupIsOpenAtFirst() {
        compare(OpenPopup.none.popup, "");
        compare(OpenPopup.none.window, null);
    }

    function test_clickingAnElementOpensItsPopup() {
        const open = OpenPopup.requested(OpenPopup.none, "battery", leftBar);
        compare(open.popup, "battery");
        compare(open.window, leftBar);
    }

    function test_clickingTheSameElementAgainClosesIt() {
        const open = OpenPopup.requested(OpenPopup.none, "battery", leftBar);
        compare(OpenPopup.requested(open, "battery", leftBar), OpenPopup.none);
    }

    function test_clickingAnotherElementSwitchesToItsPopup() {
        const open = OpenPopup.requested(OpenPopup.none, "battery", leftBar);
        const next = OpenPopup.requested(open, "network", leftBar);
        compare(next.popup, "network");
        compare(next.window, leftBar);
    }

    function test_theSamePopupOnAnotherBarMovesThere() {
        const open = OpenPopup.requested(OpenPopup.none, "battery", leftBar);
        const next = OpenPopup.requested(open, "battery", rightBar);
        compare(next.popup, "battery");
        compare(next.window, rightBar);
    }

    function test_theOpenPopupClosingLeavesNoneOpen() {
        const open = OpenPopup.requested(OpenPopup.none, "battery", leftBar);
        compare(OpenPopup.closed(open, "battery", leftBar), OpenPopup.none);
    }

    // A popup that closes after another one took its place (it lost focus
    // to the click that opened the other) leaves the new one open.
    function test_aPopupThatIsNoLongerOpenClosingChangesNothing() {
        const open = OpenPopup.requested(OpenPopup.none, "network", leftBar);
        compare(OpenPopup.closed(open, "battery", leftBar), open);
        compare(OpenPopup.closed(open, "network", rightBar), open);
    }

    // IPC (`notifications toggle`) opens a popup on the bar of the monitor
    // with keyboard focus.
    readonly property var bars: [
        { window: leftBar, monitor: "Philips", visible: true },
        { window: rightBar, monitor: "AOC", visible: true }
    ]

    function test_ipcOpensThePopupOnTheFocusedMonitorsBar() {
        const open = OpenPopup.toggledOnFocusedBar(OpenPopup.none, "controlCenter", bars, "AOC");
        compare(open.popup, "controlCenter");
        compare(open.window, rightBar);
    }

    function test_ipcAgainOnTheSameBarClosesIt() {
        const open = OpenPopup.toggledOnFocusedBar(OpenPopup.none, "controlCenter", bars, "AOC");
        compare(OpenPopup.toggledOnFocusedBar(open, "controlCenter", bars, "AOC"), OpenPopup.none);
    }

    function test_ipcReplacesAnotherOpenPopup() {
        const open = OpenPopup.requested(OpenPopup.none, "battery", leftBar);
        const next = OpenPopup.toggledOnFocusedBar(open, "controlCenter", bars, "Philips");
        compare(next.popup, "controlCenter");
        compare(next.window, leftBar);
    }

    // A monitor whose bar is hidden can't hold the popup: it opens on the
    // first bar that is shown.
    function test_ipcFallsBackToAShownBarWhenTheFocusedOneIsHidden() {
        const hidden = [
            { window: leftBar, monitor: "Philips", visible: true },
            { window: rightBar, monitor: "AOC", visible: false }
        ];
        const open = OpenPopup.toggledOnFocusedBar(OpenPopup.none, "controlCenter", hidden, "AOC");
        compare(open.window, leftBar);
    }

    // Quick settings' control center button opens it, never closes it.
    function test_openingOnTheFocusedBarKeepsItOpenWhenItAlreadyIs() {
        const open = OpenPopup.openedOnFocusedBar(OpenPopup.none, "controlCenter", bars, "AOC");
        compare(open.popup, "controlCenter");
        compare(open.window, rightBar);
        compare(OpenPopup.openedOnFocusedBar(open, "controlCenter", bars, "AOC"), open);
    }

    function test_openingWithNoShownBarChangesNothing() {
        const open = OpenPopup.requested(OpenPopup.none, "battery", leftBar);
        compare(OpenPopup.openedOnFocusedBar(open, "controlCenter", [], "AOC"), open);
    }

    function test_ipcWithNoShownBarChangesNothing() {
        const open = OpenPopup.requested(OpenPopup.none, "battery", leftBar);
        compare(OpenPopup.toggledOnFocusedBar(open, "controlCenter", [], "AOC"), open);
    }
    // SUPER+C asks for "expanded", SUPER+N for "collapsed". Closed, the
    // shortcut opens the control center at its stage on the focused bar.
    function test_aShortcutOpensTheClosedControlCenterAtItsStage() {
        const next = OpenPopup.controlCenterShortcut(OpenPopup.none, "collapsed", "expanded",
            bars, "AOC", true);
        compare(next.open.popup, "controlCenter");
        compare(next.open.window, rightBar);
        compare(next.stage, "expanded");
    }

    function controlCenterOn(window) {
        return OpenPopup.requested(OpenPopup.none, "controlCenter", window);
    }

    // SUPER+C on the open collapsed control center expands it; SUPER+N on
    // the expanded one collapses it. It stays open.
    function test_aShortcutSwitchesTheOpenControlCenterToItsStage() {
        const open = controlCenterOn(rightBar);
        const expanded = OpenPopup.controlCenterShortcut(open, "collapsed", "expanded", bars, "AOC",
            true);
        compare(expanded.open, open);
        compare(expanded.stage, "expanded");
        const collapsed = OpenPopup.controlCenterShortcut(open, "expanded", "collapsed", bars,
            "AOC", true);
        compare(collapsed.open, open);
        compare(collapsed.stage, "collapsed");
    }

    // SUPER+C on the expanded control center closes it; SUPER+N on the
    // collapsed one closes it.
    function test_aShortcutClosesTheControlCenterAtItsOwnStage() {
        const open = controlCenterOn(rightBar);
        compare(OpenPopup.controlCenterShortcut(open, "expanded", "expanded", bars, "AOC", true).open,
            OpenPopup.none);
        compare(OpenPopup.controlCenterShortcut(open, "collapsed", "collapsed", bars, "AOC", true)
            .open, OpenPopup.none);
    }

    // Open on another monitor's bar, it moves to the focused one rather than
    // closing.
    function test_aShortcutMovesTheControlCenterOpenOnAnotherBarToTheFocusedOne() {
        const next = OpenPopup.controlCenterShortcut(controlCenterOn(leftBar), "expanded",
            "expanded", bars, "AOC", true);
        compare(next.open.window, rightBar);
        compare(next.stage, "expanded");
    }

    function test_aShortcutWithNoShownBarChangesNothing() {
        const open = controlCenterOn(leftBar);
        const next = OpenPopup.controlCenterShortcut(open, "collapsed", "expanded", [], "AOC", true);
        compare(next.open, open);
        compare(next.stage, "collapsed");
    }

    // With the control center plugin off it has no stages: either shortcut
    // opens it and, open, closes it.
    function test_withThePluginOffAShortcutJustTogglesIt() {
        const opened = OpenPopup.controlCenterShortcut(OpenPopup.none, "collapsed", "expanded",
            bars, "AOC", false);
        compare(opened.open.window, rightBar);
        compare(OpenPopup.controlCenterShortcut(opened.open, "collapsed", "expanded", bars, "AOC",
            false).open, OpenPopup.none);
    }
}
