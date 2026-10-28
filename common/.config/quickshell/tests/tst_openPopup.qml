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
}
