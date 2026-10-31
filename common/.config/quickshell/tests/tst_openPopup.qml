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
}
