import QtQuick
import QtTest
import "../components/panels/PopupPlacement.js" as PopupPlacement

// A popup opens under the bar element that opened it when that element sits
// in the center zone, shifted sideways to stay on screen; otherwise it opens
// at the bar's edge.
TestCase {
    name: "PopupPlacement"

    // A 1920 px wide bar, 40 px tall, with 12 px of horizontal padding.
    readonly property var bar: ({ barWidth: 1920, barHeight: 40, padding: 12, spacing: 8 })

    function placement(fields) {
        return Object.assign({
            popupWidth: 400,
            nearTrigger: true,
            trigger: { x: 900, width: 120 },
            edge: "right"
        }, bar, fields);
    }

    function test_aPopupOpensCenteredUnderItsBarElement() {
        compare(PopupPlacement.x(placement({})), 760);
    }

    function test_aPopupNearTheLeftEndShiftsRightToStayOnScreen() {
        compare(PopupPlacement.x(placement({ trigger: { x: 20, width: 60 } })), 12);
    }

    function test_aPopupNearTheRightEndShiftsLeftToStayOnScreen() {
        compare(PopupPlacement.x(placement({ trigger: { x: 1860, width: 60 } })), 1508);
    }

    function test_aPopupOfAnElementOutsideTheCenterOpensAtTheRightEdge() {
        compare(PopupPlacement.x(placement({ nearTrigger: false })), 1508);
    }

    function test_aPopupCanOpenAtTheLeftEdgeInstead() {
        compare(PopupPlacement.x(placement({ nearTrigger: false, edge: "left" })), 12);
    }

    function test_aCenterPopupWhoseElementIsMissingOpensAtTheRightEdge() {
        compare(PopupPlacement.x(placement({ trigger: null, edge: "left" })), 1508);
    }

    function test_aCenterPopupOpensJustBelowTheBarContent() {
        compare(PopupPlacement.y(placement({ content: { y: 6, height: 32 } })), 46);
    }

    function test_anEdgePopupOpensBelowTheBarHeight() {
        compare(PopupPlacement.y(placement({ nearTrigger: false, content: { y: 6, height: 32 } })), 48);
    }

    function test_popupsAreAttachedOnAnOpaqueBar() {
        verify(PopupPlacement.attached({ barTransparent: false }));
    }

    function test_popupsFloatOnATransparentBar() {
        verify(!PopupPlacement.attached({ barTransparent: true }));
    }

    function test_anAttachedPopupOpensRightAtTheBarsBottomEdge() {
        compare(PopupPlacement.y(placement({ attached: true, content: { y: 6, height: 32 } })), 40);
        compare(PopupPlacement.y(placement({ attached: true, nearTrigger: false })), 40);
    }

    function test_aFloatingPopupHasRoomAllAroundItsSurface() {
        compare(PopupPlacement.room({ attached: false, inset: 12, joinRadius: 6 }),
            { top: 12, side: 12, bottom: 12 });
    }

    function test_anAttachedPopupTouchesTheBarWithRoomOnlyForItsCurvedJoins() {
        compare(PopupPlacement.room({ attached: true, inset: 12, joinRadius: 6 }),
            { top: 0, side: 6, bottom: 0 });
    }
}
