import QtQuick
import QtTest
import "../components/panels/PopupGrab.js" as PopupGrab

// What a popup's focus grab holds. It starts on the popup alone, so the
// keyboard lands there and not on the bar under the mouse, and takes the bar
// in once it holds, so bar elements stay clickable.
TestCase {
    name: "PopupGrab"

    readonly property var popup: ({ name: "popup" })
    readonly property var bar: ({ name: "bar" })

    function test_aGrabStartsOnThePopupAlone() {
        compare(PopupGrab.windows(popup, bar, false), [popup]);
    }

    function test_aGrabThatHoldsTakesTheBarIn() {
        compare(PopupGrab.windows(popup, bar, true), [popup, bar]);
    }
}
