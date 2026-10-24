import QtQuick
import QtTest
import "../components/panels/PopupOutline.js" as PopupOutline

// An attached popup has square top corners, small curved corners joining it to
// the bar's bottom edge, and rounded bottom corners. While it unfolds the
// corners shrink so they never cross each other.
TestCase {
    name: "PopupOutline"

    function test_anOpenPopupHasItsFullJoinsAndBottomCorners() {
        compare(PopupOutline.attachedCorners({ width: 300, height: 200, radius: 12, joinRadius: 6 }),
            { join: 6, bottom: 12 });
    }

    function test_aShortPopupRoundsItsBottomByAtMostHalfItsHeight() {
        compare(PopupOutline.attachedCorners({ width: 300, height: 10, radius: 12, joinRadius: 6 }).bottom, 5);
    }

    function test_theJoinsShrinkWhenThePopupIsShorterThanBothCorners() {
        compare(PopupOutline.attachedCorners({ width: 300, height: 16, radius: 12, joinRadius: 6 }),
            { join: 6, bottom: 8 });
        compare(PopupOutline.attachedCorners({ width: 300, height: 10, radius: 12, joinRadius: 6 }),
            { join: 5, bottom: 5 });
    }

    function test_aFoldedPopupHasNoCorners() {
        compare(PopupOutline.attachedCorners({ width: 300, height: 0, radius: 12, joinRadius: 6 }),
            { join: 0, bottom: 0 });
    }
}
