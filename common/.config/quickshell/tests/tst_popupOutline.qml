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
