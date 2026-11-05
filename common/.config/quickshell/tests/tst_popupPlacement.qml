import QtQuick
import QtTest
import "../components/panels/PopupPlacement.js" as PopupPlacement

// A popup opens away from the bar, towards the inside of the screen, centred on
// the bar element that opened it, whatever zone it sits in, shifted along the
// bar to stay on screen and clear of the bar's rounded ends. A popup whose
// element isn't on the bar opens at the bar's edge.
TestCase {
    name: "PopupPlacement"

    // A 1920 px wide bar, 40 px tall, with 12 px of horizontal padding.
    readonly property var bar: ({
        barPosition: "top",
        window: { width: 1920, height: 40 },
        barHeight: 40,
        padding: 12,
        spacing: 8
    })
    // The same bar on each edge of a 1920x1080 screen.
    readonly property var windows: ({
        top: { width: 1920, height: 40 },
        bottom: { width: 1920, height: 40 },
        left: { width: 40, height: 1080 },
        right: { width: 40, height: 1080 }
    })

    function placement(fields) {
        return Object.assign({
            popupWidth: 400,
            popupHeight: 300,
            trigger: { start: 900, length: 120 },
            edge: "right"
        }, bar, fields);
    }

    // A popup of the bar on the given edge, its element centred at 550 along
    // the bar.
    function placedOn(barPosition, fields) {
        return PopupPlacement.position(placement(Object.assign({
            barPosition: barPosition,
            window: windows[barPosition],
            trigger: { start: 500, length: 100 }
        }, fields)));
    }

    function test_aPopupOpensCenteredUnderItsBarElement() {
        compare(PopupPlacement.position(placement({})).x, 760);
    }

    function test_aPopupNearTheLeftEndShiftsRightToStayOnScreen() {
        compare(PopupPlacement.position(placement({ trigger: { start: 20, length: 60 } })).x, 12);
    }

    function test_aPopupNearTheRightEndShiftsLeftToStayOnScreen() {
        compare(PopupPlacement.position(placement({ trigger: { start: 1860, length: 60 } })).x, 1508);
    }

    function test_aPopupOfALeftZoneElementOpensUnderIt() {
        compare(PopupPlacement.position(placement({ trigger: { start: 300, length: 60 } })).x, 130);
    }

    function test_aPopupOfARightZoneElementOpensUnderIt() {
        compare(PopupPlacement.position(placement({ trigger: { start: 1600, length: 60 } })).x, 1430);
    }

    function test_aPopupKeepsClearOfTheBarsRoundedEnds() {
        compare(PopupPlacement.position(placement({ radius: 20, trigger: { start: 20, length: 60 } })).x, 20);
        compare(PopupPlacement.position(placement({ radius: 20, trigger: { start: 1860, length: 60 } })).x, 1500);
    }

    function test_aSmallRadiusLeavesThePaddingAsTheMargin() {
        compare(PopupPlacement.position(placement({ radius: 6, trigger: { start: 20, length: 60 } })).x, 12);
    }

    function test_aPopupWhoseElementIsNotOnTheBarOpensAtTheRightEdge() {
        compare(PopupPlacement.position(placement({ trigger: null })).x, 1508);
    }

    function test_aPopupCanOpenAtTheLeftEdgeInstead() {
        compare(PopupPlacement.position(placement({ trigger: null, edge: "left" })).x, 12);
    }

    function test_anEdgePopupKeepsClearOfTheBarsRoundedEnds() {
        compare(PopupPlacement.position(placement({ radius: 20, trigger: null })).x, 1500);
        compare(PopupPlacement.position(placement({ radius: 20, trigger: null, edge: "left" })).x, 20);
    }

    function test_aFloatingPopupOpensJustBelowTheBarContent() {
        compare(PopupPlacement.position(placement({ content: { y: 6, height: 32 } })).y, 46);
    }

    function test_aFloatingPopupWithoutBarContentOpensBelowTheBarHeight() {
        compare(PopupPlacement.position(placement({ content: null })).y, 48);
    }

    function test_popupsAreAttachedOnAnOpaqueBar() {
        verify(PopupPlacement.attached({ barTransparent: false }));
    }

    function test_popupsFloatOnATransparentBar() {
        verify(!PopupPlacement.attached({ barTransparent: true }));
    }

    function test_popupsAreAttachedOnADockedBar() {
        verify(PopupPlacement.attached({ barTransparent: true, transparentBarSlanted: true }));
    }

    function test_anAttachedPopupOnATopBarOpensRightAtItsBottomEdge() {
        compare(PopupPlacement.position(placement({ attached: true, content: { y: 6, height: 32 } })).y, 40);
        compare(PopupPlacement.position(placement({ attached: true, content: null })).y, 40);
    }

    function test_anAttachedPopupOpensRightAtTheBar_data() {
        return [
            { tag: "top", x: 350, y: 40 },
            { tag: "bottom", x: 350, y: -300 },
            { tag: "left", x: 40, y: 400 },
            { tag: "right", x: -400, y: 400 }
        ];
    }

    function test_anAttachedPopupOpensRightAtTheBar(data) {
        const placed = placedOn(data.tag, { attached: true, content: null });

        compare(placed.x, data.x);
        compare(placed.y, data.y);
    }

    function test_aFloatingPopupOpensClearOfTheBar_data() {
        return [
            { tag: "top", x: 350, y: 48 },
            { tag: "bottom", x: 350, y: -308 },
            { tag: "left", x: 48, y: 400 },
            { tag: "right", x: -408, y: 400 }
        ];
    }

    function test_aFloatingPopupOpensClearOfTheBar(data) {
        const placed = placedOn(data.tag, { attached: false, content: null });

        compare(placed.x, data.x);
        compare(placed.y, data.y);
    }

    // A transparent bar 6 px from its screen edge, in a window 46 px thick,
    // its 32 px content ending 38 px in from that edge.
    function test_aFloatingPopupOpensJustPastTheBarContent_data() {
        return [
            { tag: "top", window: { width: 1920, height: 46 },
                content: { x: 0, y: 6, width: 1920, height: 32 }, x: 350, y: 46 },
            { tag: "bottom", window: { width: 1920, height: 46 },
                content: { x: 0, y: 8, width: 1920, height: 32 }, x: 350, y: -300 },
            { tag: "left", window: { width: 46, height: 1080 },
                content: { x: 6, y: 0, width: 32, height: 1080 }, x: 46, y: 400 },
            { tag: "right", window: { width: 46, height: 1080 },
                content: { x: 8, y: 0, width: 32, height: 1080 }, x: -400, y: 400 }
        ];
    }

    function test_aFloatingPopupOpensJustPastTheBarContent(data) {
        const placed = placedOn(data.tag, { window: data.window, content: data.content });

        compare(placed.x, data.x);
        compare(placed.y, data.y);
    }

    function test_aPopupOnASideBarShiftsAlongItToStayOnScreen_data() {
        return [
            { tag: "left bar, top end", position: "left", start: 20, y: 12 },
            { tag: "left bar, bottom end", position: "left", start: 1020, y: 768 },
            { tag: "right bar, top end", position: "right", start: 20, y: 12 },
            { tag: "right bar, bottom end", position: "right", start: 1020, y: 768 }
        ];
    }

    function test_aPopupOnASideBarShiftsAlongItToStayOnScreen(data) {
        const placed = placedOn(data.position, { trigger: { start: data.start, length: 60 } });

        compare(placed.y, data.y);
    }

    function test_aPopupOnASideBarKeepsClearOfTheBarsRoundedEnds() {
        compare(placedOn("left", { radius: 20, trigger: { start: 20, length: 60 } }).y, 20);
        compare(placedOn("right", { radius: 20, trigger: { start: 1020, length: 60 } }).y, 760);
    }

    function test_onASideBarTheFallbackMeansTopOrBottom_data() {
        return [
            { tag: "left bar, left means top", position: "left", edge: "left", y: 12 },
            { tag: "left bar, right means bottom", position: "left", edge: "right", y: 768 },
            { tag: "right bar, left means top", position: "right", edge: "left", y: 12 },
            { tag: "right bar, right means bottom", position: "right", edge: "right", y: 768 }
        ];
    }

    function test_onASideBarTheFallbackMeansTopOrBottom(data) {
        const placed = placedOn(data.position, { trigger: null, edge: data.edge });

        compare(placed.y, data.y);
    }

    function test_aBottomBarsFallbackIsStillLeftOrRight() {
        compare(placedOn("bottom", { trigger: null, edge: "left" }).x, 12);
        compare(placedOn("bottom", { trigger: null, edge: "right" }).x, 1508);
    }

    function test_thePopupsSpanIsMeasuredAlongTheBar_data() {
        return [
            { tag: "top", start: 350, end: 750 },
            { tag: "bottom", start: 350, end: 750 },
            { tag: "left", start: 400, end: 700 },
            { tag: "right", start: 400, end: 700 }
        ];
    }

    function test_thePopupsSpanIsMeasuredAlongTheBar(data) {
        const placed = placedOn(data.tag, {});

        compare(placed.start, data.start);
        compare(placed.end, data.end);
    }

    function test_aFloatingPopupHasRoomAllAroundItsSurface_data() {
        return [{ tag: "top" }, { tag: "bottom" }, { tag: "left" }, { tag: "right" }];
    }

    function test_aFloatingPopupHasRoomAllAroundItsSurface(data) {
        compare(PopupPlacement.room({ barPosition: data.tag, attached: false, inset: 12, joinRadius: 6 }),
            { top: 12, right: 12, bottom: 12, left: 12 });
    }

    function test_anAttachedPopupTouchesTheBarWithRoomOnlyForItsCurvedJoins_data() {
        return [
            { tag: "top", room: { top: 0, right: 6, bottom: 0, left: 6 } },
            { tag: "bottom", room: { top: 0, right: 6, bottom: 0, left: 6 } },
            { tag: "left", room: { top: 6, right: 0, bottom: 6, left: 0 } },
            { tag: "right", room: { top: 6, right: 0, bottom: 6, left: 0 } }
        ];
    }

    function test_anAttachedPopupTouchesTheBarWithRoomOnlyForItsCurvedJoins(data) {
        compare(PopupPlacement.room({ barPosition: data.tag, attached: true, inset: 12, joinRadius: 6 }),
            data.room);
    }

    function test_aDistanceTowardsTheBar_data() {
        return [
            { tag: "top", offset: { x: 0, y: -8 } },
            { tag: "bottom", offset: { x: 0, y: 8 } },
            { tag: "left", offset: { x: -8, y: 0 } },
            { tag: "right", offset: { x: 8, y: 0 } }
        ];
    }

    function test_aDistanceTowardsTheBar(data) {
        compare(PopupPlacement.towardsBar(data.tag, 8), data.offset);
    }

    // A control center on a side bar of 1080 px, switching stages between 300
    // and 700 px long: the window is held 700 long and the popup resizes in it.
    // Its element is in the middle of the bar, or near either end.
    function test_aHeldPopupStaysSteadyOnASideBar_data() {
        const cases = [
            { tag: "bell in the middle", trigger: { start: 500, length: 30 } },
            { tag: "bell near the top", trigger: { start: 16, length: 30 } },
            { tag: "bell near the bottom", trigger: { start: 1040, length: 30 } },
            { tag: "no bell", trigger: null }
        ];

        return ["left", "right"].reduce((all, position) => all.concat(cases.map(item =>
            ({ tag: position + ", " + item.tag, position: position, trigger: item.trigger }))), []);
    }

    function test_aHeldPopupStaysSteadyOnASideBar(data) {
        const fields = { trigger: data.trigger, popupHeight: 700 };
        const held = placedOn(data.position, fields);

        for (let length = 300; length <= 700; length += 10) {
            const placed = placedOn(data.position, Object.assign({ restingHeight: length }, fields));
            const resting = placedOn(data.position, { trigger: data.trigger, popupHeight: length });
            const tag = "resting at " + length;

            compare(placed.y, held.y, tag + ": the window holds still");
            compare(placed.x, held.x, tag + ": the window holds still across the bar");
            compare(placed.start, resting.y, tag + ": the popup is where it rests");
            compare(placed.end, resting.y + length, tag + ": the popup ends where it rests");
            compare(placed.y + placed.surfaceShift, resting.y, tag + ": the surface is where it rests");
            verify(placed.surfaceShift >= 0, tag + ": the surface starts in the window");
            verify(placed.surfaceShift + length <= 700, tag + ": the surface ends in the window");
            verify(placed.start >= 12, tag + ": it stays on screen at the start");
            verify(placed.end <= 1080 - 12, tag + ": it stays on screen at the end");
        }
    }

    function test_aPopupNotHeldSitsAtTheStartOfItsWindow_data() {
        return [{ tag: "top" }, { tag: "bottom" }, { tag: "left" }, { tag: "right" }];
    }

    function test_aPopupNotHeldSitsAtTheStartOfItsWindow(data) {
        compare(placedOn(data.tag, {}).surfaceShift, 0);
        compare(placedOn(data.tag, { restingHeight: 300 }).surfaceShift, 0);
    }

    // The hold runs away from a top or bottom bar, so nothing moves along it.
    function test_aHoldDoesntMoveAPopupAlongATopOrBottomBar_data() {
        return [{ tag: "top" }, { tag: "bottom" }];
    }

    function test_aHoldDoesntMoveAPopupAlongATopOrBottomBar(data) {
        const placed = placedOn(data.tag, { popupHeight: 700, restingHeight: 300 });
        const window = placedOn(data.tag, { popupHeight: 700 });

        compare(placed.surfaceShift, 0);
        compare(placed.x, window.x);
        compare(placed.y, window.y);
        compare(placed.start, window.start);
        compare(placed.end, window.end);
    }

    function test_aTriggerIsMeasuredAlongTheBar_data() {
        return [
            { tag: "top", span: { start: 130, length: 60 } },
            { tag: "bottom", span: { start: 130, length: 60 } },
            { tag: "left", span: { start: 56, length: 24 } },
            { tag: "right", span: { start: 56, length: 24 } }
        ];
    }

    function test_aTriggerIsMeasuredAlongTheBar(data) {
        const content = { x: 10, y: 6 };
        const element = { x: 120, y: 50, width: 60, height: 24 };

        compare(PopupPlacement.triggerSpan(data.tag, content, element), data.span);
    }

    function test_nothingTriggersAPopupWhoseElementIsntOnTheBar() {
        compare(PopupPlacement.triggerSpan("left", { x: 0, y: 0 }, null), null);
    }
}
