import QtQuick
import QtTest
import "../components/panels/PopupOutline.js" as PopupOutline

// An attached popup has square corners against the bar, small curved corners
// joining it to the bar, and rounded corners away from it, on whichever screen
// edge the bar sits. While it unfolds the corners shrink so they never cross
// each other.
TestCase {
    name: "PopupOutline"

    // The outline of a 300x200 surface, every point in surface coordinates:
    // [x, y] for lines, [x, y, controlX, controlY] for curves, from the start.
    function outline(barPosition, unfolded) {
        const path = PopupOutline.attachedPath({
            barPosition: barPosition,
            width: 300,
            height: 200,
            unfolded: unfolded,
            radius: 12,
            joinRadius: 6
        });
        const points = [[path.start.x + path.x, path.start.y + path.y]];

        for (const segment of path.segments) {
            points.push(segment.controlX === undefined
                ? [segment.x + path.x, segment.y + path.y]
                : [segment.x + path.x, segment.y + path.y,
                    segment.controlX + path.x, segment.controlY + path.y]);
        }
        return points;
    }

    function test_theOutlineFollowsTheBarOnEveryEdge_data() {
        return [
            { tag: "top", unfolded: 200, points: [
                [-6, 0], [306, 0], [300, 6, 300, 0], [300, 188], [288, 200, 300, 200],
                [12, 200], [0, 188, 0, 200], [0, 6], [-6, 0, 0, 0]
            ] },
            { tag: "bottom", unfolded: 200, points: [
                [-6, 200], [306, 200], [300, 194, 300, 200], [300, 12], [288, 0, 300, 0],
                [12, 0], [0, 12, 0, 0], [0, 194], [-6, 200, 0, 200]
            ] },
            { tag: "left", unfolded: 300, points: [
                [0, -6], [0, 206], [6, 200, 0, 200], [288, 200], [300, 188, 300, 200],
                [300, 12], [288, 0, 300, 0], [6, 0], [0, -6, 0, 0]
            ] },
            { tag: "right", unfolded: 300, points: [
                [300, -6], [300, 206], [294, 200, 300, 200], [12, 200], [0, 188, 0, 200],
                [0, 12], [12, 0, 0, 0], [294, 0], [300, -6, 300, 0]
            ] }
        ];
    }

    function test_theOutlineFollowsTheBarOnEveryEdge(data) {
        compare(outline(data.tag, data.unfolded), data.points);
    }

    function test_theOutlinesBoxCoversOnlyWhatHasUnfolded_data() {
        return [
            { tag: "top", box: { x: -6, y: 0, width: 312, height: 50 } },
            { tag: "bottom", box: { x: -6, y: 150, width: 312, height: 50 } },
            { tag: "left", box: { x: 0, y: -6, width: 50, height: 212 } },
            { tag: "right", box: { x: 250, y: -6, width: 50, height: 212 } }
        ];
    }

    function test_theOutlinesBoxCoversOnlyWhatHasUnfolded(data) {
        const path = PopupOutline.attachedPath({
            barPosition: data.tag,
            width: 300,
            height: 200,
            unfolded: 49.5,
            radius: 12,
            joinRadius: 6
        });

        compare({ x: path.x, y: path.y, width: path.width, height: path.height }, data.box);
    }

    function test_aPartlyUnfoldedOutlineStopsWhereItHasUnfolded() {
        compare(outline("bottom", 49.5)[5], [12, 150.5]);
        compare(outline("right", 49.5)[3], [250.5 + 12, 200]);
    }

    function test_whatHasUnfoldedStartsAtTheBar_data() {
        return [
            { tag: "top", area: { x: 0, y: 0, width: 300, height: 50 } },
            { tag: "bottom", area: { x: 0, y: 150, width: 300, height: 50 } },
            { tag: "left", area: { x: 0, y: 0, width: 50, height: 200 } },
            { tag: "right", area: { x: 250, y: 0, width: 50, height: 200 } }
        ];
    }

    function test_whatHasUnfoldedStartsAtTheBar(data) {
        compare(PopupOutline.unfoldedArea({ barPosition: data.tag, width: 300, height: 200, unfolded: 50 }),
            data.area);
    }

    // A docked zone 200 long and 30 deep, as [x, y] lines and
    // [x, y, controlX, controlY] curves in the zone, from the start.
    function zoneOutline(barPosition, options) {
        const path = PopupOutline.dockedPath(Object.assign({
            barPosition: barPosition,
            length: 200,
            depth: 30,
            radius: 8,
            joinRadius: 6
        }, options));
        const points = [[path.start.x, path.start.y]];

        for (const segment of path.segments) {
            points.push(segment.controlX === undefined
                ? [segment.x, segment.y]
                : [segment.x, segment.y, segment.controlX, segment.controlY]);
        }
        return points;
    }

    function test_aDockedZoneFollowsTheBarOnEveryEdge_data() {
        return [
            { tag: "top", points: [
                [0, 0], [200, 0], [194, 6, 194, 0], [194, 22], [186, 30, 194, 30],
                [14, 30], [6, 22, 6, 30], [6, 6], [0, 0, 6, 0]
            ] },
            { tag: "bottom", points: [
                [0, 30], [200, 30], [194, 24, 194, 30], [194, 8], [186, 0, 194, 0],
                [14, 0], [6, 8, 6, 0], [6, 24], [0, 30, 6, 30]
            ] },
            { tag: "left", points: [
                [0, 0], [0, 200], [6, 194, 0, 194], [22, 194], [30, 186, 30, 194],
                [30, 14], [22, 6, 30, 6], [6, 6], [0, 0, 0, 6]
            ] },
            { tag: "right", points: [
                [30, 0], [30, 200], [24, 194, 30, 194], [8, 194], [0, 186, 0, 194],
                [0, 14], [8, 6, 0, 6], [24, 6], [30, 0, 30, 6]
            ] }
        ];
    }

    function test_aDockedZoneFollowsTheBarOnEveryEdge(data) {
        compare(zoneOutline(data.tag), data.points);
    }

    function test_aDockedZoneKeepsItsSideOnTheScreensEdgeStraight_data() {
        return [
            { tag: "start on top", barPosition: "top", keepStart: true, points: [
                [0, 0], [200, 0], [194, 6, 194, 0], [194, 22], [186, 30, 194, 30], [0, 30]
            ] },
            { tag: "end on top", barPosition: "top", keepEnd: true, points: [
                [0, 0], [200, 0], [200, 30], [14, 30], [6, 22, 6, 30], [6, 6], [0, 0, 6, 0]
            ] },
            { tag: "start on the bottom", barPosition: "bottom", keepStart: true, points: [
                [0, 30], [200, 30], [194, 24, 194, 30], [194, 8], [186, 0, 194, 0], [0, 0]
            ] },
            { tag: "end on the bottom", barPosition: "bottom", keepEnd: true, points: [
                [0, 30], [200, 30], [200, 0], [14, 0], [6, 8, 6, 0], [6, 24], [0, 30, 6, 30]
            ] },
            { tag: "start on the left", barPosition: "left", keepStart: true, points: [
                [0, 0], [0, 200], [6, 194, 0, 194], [22, 194], [30, 186, 30, 194], [30, 0]
            ] },
            { tag: "end on the left", barPosition: "left", keepEnd: true, points: [
                [0, 0], [0, 200], [30, 200], [30, 14], [22, 6, 30, 6], [6, 6], [0, 0, 0, 6]
            ] },
            { tag: "start on the right", barPosition: "right", keepStart: true, points: [
                [30, 0], [30, 200], [24, 194, 30, 194], [8, 194], [0, 186, 0, 194], [0, 0]
            ] },
            { tag: "end on the right", barPosition: "right", keepEnd: true, points: [
                [30, 0], [30, 200], [0, 200], [0, 14], [8, 6, 0, 6], [24, 6], [30, 0, 30, 6]
            ] }
        ];
    }

    function test_aDockedZoneKeepsItsSideOnTheScreensEdgeStraight(data) {
        compare(zoneOutline(data.barPosition, { keepStart: data.keepStart, keepEnd: data.keepEnd }),
            data.points);
    }

    function test_aThinDockedZoneShrinksItsCornersAsAPopupDoes() {
        compare(zoneOutline("top", { depth: 10 }), [
            [0, 0], [200, 0], [195, 5, 195, 0], [195, 5], [190, 10, 195, 10],
            [10, 10], [5, 5, 5, 10], [5, 5], [0, 0, 5, 0]
        ]);
    }

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

    function test_anAttachedOutlineNamesItsSegments() {
        const path = PopupOutline.attachedPath({
            barPosition: "top",
            width: 400,
            height: 300,
            unfolded: 300,
            radius: 8,
            joinRadius: 6
        });

        compare(path.parts.barSide, { x: 412, y: 0 });
        compare(path.parts.endJoin, { x: 406, y: 6, controlX: 406, controlY: 0 });
        compare(path.parts.endSide, { x: 406, y: 292 });
        compare(path.parts.endCorner, { x: 398, y: 300, controlX: 406, controlY: 300 });
        compare(path.parts.farSide, { x: 14, y: 300 });
        compare(path.parts.startCorner, { x: 6, y: 292, controlX: 6, controlY: 300 });
        compare(path.parts.startSide, { x: 6, y: 6 });
        compare(path.parts.startJoin, { x: 0, y: 0, controlX: 6, controlY: 0 });
    }

    // The bar border round a 300x200 attached surface, as outline() gives it.
    function attachedBorder(barPosition, unfolded) {
        const path = PopupOutline.attachedBorder({
            barPosition: barPosition,
            width: 300,
            height: 200,
            unfolded: unfolded,
            radius: 12,
            joinRadius: 6
        });

        return [path.start].concat(path.segments).map(point => point.controlX === undefined
            ? [point.x + path.x, point.y + path.y]
            : [point.x + path.x, point.y + path.y, point.controlX + path.x, point.controlY + path.y]);
    }

    // Runs as lists of points, as outline() gives them.
    function runPoints(runs) {
        return runs.map(run => [run.start].concat(run.segments).map(point =>
            point.controlX === undefined ? [point.x, point.y]
                : [point.x, point.y, point.controlX, point.controlY]));
    }

    function test_anAttachedBorderLeavesOutTheSideAgainstTheBar_data() {
        return [
            { tag: "top", unfolded: 200, points: [
                [305.5, 0], [299.5, 6, 299.5, 0], [299.5, 187.5], [287.5, 199.5, 299.5, 199.5],
                [12.5, 199.5], [0.5, 187.5, 0.5, 199.5], [0.5, 6], [-5.5, 0, 0.5, 0]
            ] },
            { tag: "right", unfolded: 300, points: [
                [300, 205.5], [294, 199.5, 300, 199.5], [12.5, 199.5], [0.5, 187.5, 0.5, 199.5],
                [0.5, 12.5], [12.5, 0.5, 0.5, 0.5], [294, 0.5], [300, -5.5, 300, 0.5]
            ] }
        ];
    }

    // Half a pixel inside the outline, so the 1px line covers its edge pixel.
    function test_anAttachedBorderLeavesOutTheSideAgainstTheBar(data) {
        compare(attachedBorder(data.tag, data.unfolded), data.points);
    }

    function test_anAttachedBorderNamesItsParts() {
        const path = PopupOutline.attachedBorder({
            barPosition: "top", width: 300, height: 200, unfolded: 200, radius: 12, joinRadius: 6
        });

        compare(path.parts.endJoin, path.segments[0]);
        compare(path.parts.startJoin, path.segments[6]);
    }

    function dockedBorder(options) {
        return runPoints(PopupOutline.dockedBorder(Object.assign({
            barPosition: "top", length: 200, depth: 30, radius: 8, joinRadius: 6,
            keepStart: false, keepEnd: false, gap: null
        }, options)));
    }

    function test_aDockedBorderLeavesOutTheScreenEdge() {
        compare(dockedBorder({}), [[
            [199.5, 0], [193.5, 6, 193.5, 0], [193.5, 21.5], [185.5, 29.5, 193.5, 29.5],
            [14.5, 29.5], [6.5, 21.5, 6.5, 29.5], [6.5, 6], [0.5, 0, 6.5, 0]
        ]]);
    }

    function test_aDockedBorderBreaksWhereAPopupHangsFromIt() {
        compare(dockedBorder({ gap: { start: 50, end: 150 } }), [
            [[199.5, 0], [193.5, 6, 193.5, 0], [193.5, 21.5], [185.5, 29.5, 193.5, 29.5], [150, 29.5]],
            [[50, 29.5], [14.5, 29.5], [6.5, 21.5, 6.5, 29.5], [6.5, 6], [0.5, 0, 6.5, 0]]
        ]);
    }

    function test_aDockedBorderLeavesOutAStraightEndOnTheScreensEdge() {
        compare(dockedBorder({ keepStart: true, keepEnd: true }), [[[200, 29.5], [0, 29.5]]]);
    }

    function test_aPopupRunningToTheScreensEdgeLeavesNoBorderPastIt() {
        compare(dockedBorder({ keepStart: true, gap: { start: 0, end: 100 } }), [
            [[199.5, 0], [193.5, 6, 193.5, 0], [193.5, 21.5], [185.5, 29.5, 193.5, 29.5], [100, 29.5]]
        ]);
    }

    function test_aDockedBorderFollowsTheBarToTheBottom() {
        compare(dockedBorder({ barPosition: "bottom", keepStart: true, keepEnd: true }),
            [[[200, 0.5], [0, 0.5]]]);
    }
}
