.pragma library
.import "../BarPosition.js" as BarPosition

// The outline of an attached popup: square corners against the bar, small
// curved corners joining it to the bar, and rounded corners away from it. A
// zone of the docked bar has the same outline. With the bar border on, both
// draw a hairline along it, which runs on from a zone round the popup hanging
// from it.

// How round its corners are at its current size, so they never cross while it
// unfolds. `height` is how far it reaches from the bar and `width` how long it
// is along it. Takes { width, height, radius, joinRadius }; returns
// { join, bottom }.
function attachedCorners(outline) {
    const bottom = Math.max(0, Math.min(outline.radius, outline.height / 2, outline.width / 2));
    const join = Math.max(0, Math.min(outline.joinRadius, outline.height - bottom));

    return { join: join, bottom: bottom };
}

// What has unfolded of a surface: the part that starts at the bar. Takes
// { barPosition, width, height, unfolded }; returns { x, y, width, height }.
function unfoldedArea(surface) {
    const sideBar = BarPosition.sideBar(surface.barPosition);

    return BarPosition.area(surface.barPosition, {
        along: 0,
        away: 0,
        length: sideBar ? surface.height : surface.width,
        depth: surface.unfolded
    }, sideBar ? surface.width : surface.height);
}

// The outline in `along` and `away` from the bar, worked out for a bar on top.
// Takes laidPath's outline. Returns the two ends of its side against the bar,
// `start` and `end`, and the rest of it from the end back round to the start:
// `endSide` up to the side away from the bar, and `startSide` from there, its
// first segment the line along that side. Points are { along, away } and
// curves { along, away, controlAlong, controlAway }.
function outlinePoints(outline) {
    const depth = outline.depth;
    const start = outline.start;
    const end = outline.end;
    const join = outline.corners.join;
    const bottom = outline.corners.bottom;
    const near = start + join;
    const far = end - join;

    function point(along, away) {
        return { along: along, away: away };
    }

    function curve(along, away, controlAlong, controlAway) {
        return { along: along, away: away, controlAlong: controlAlong, controlAway: controlAway };
    }

    return {
        start: point(start, 0),
        end: point(end, 0),
        endSide: outline.keepEnd ? [point(end, depth)] : [
            curve(far, join, far, 0),
            point(far, depth - bottom),
            curve(far - bottom, depth, far, depth)
        ],
        startSide: outline.keepStart ? [point(start, depth)] : [
            point(near + bottom, depth),
            curve(near, depth - bottom, near, depth),
            point(near, join),
            curve(start, 0, near, 0)
        ]
    };
}

// A point or curve of outlinePoints as { x, y } or { x, y, controlX, controlY },
// laid on the Bar position in a box `boxDepth` deep.
function laid(barPosition, boxDepth, item) {
    const to = BarPosition.point(barPosition, item.along, item.away, boxDepth);
    if (item.controlAlong === undefined)
        return { x: to.x, y: to.y };

    const control = BarPosition.point(barPosition, item.controlAlong, item.controlAway, boxDepth);
    return { x: to.x, y: to.y, controlX: control.x, controlY: control.y };
}

// The outline as a path, worked out for a bar on top, in `along` and `away` from
// the bar, then laid on the Bar position. Takes { barPosition, depth, boxDepth,
// start, end, corners, keepStart, keepEnd }: how far it reaches from the bar,
// the depth of the box it is laid in, where along the bar its joins start and
// end, its attachedCorners, and which ends stay straight instead of curving.
// Returns the path's start { x, y } and its segments, in order: { x, y } lines
// and { x, y, controlX, controlY } curves.
function laidPath(outline) {
    const points = outlinePoints(outline);
    const lay = item => laid(outline.barPosition, outline.boxDepth, item);

    return {
        start: lay(points.start),
        segments: [points.end].concat(points.endSide, points.startSide).map(lay)
    };
}

// How far inside an outline its bar border runs: half its 1px line, so the
// line covers the outline's outermost pixel instead of straddling its edge.
const borderInset = 0.5;

// The bar border along an outline: all of it but the side against the bar (or
// the screen edge), and an end that stays straight, which sits on the screen's
// edge. Where an attached popup hangs from the side away from the bar, the
// border leaves out that stretch, so it runs on round the popup instead. Takes
// laidPath's outline and `gap`, that stretch { start, end } along the bar, or
// null. Returns its runs, each drawn as one line from `start` through its
// `segments`, as laidPath's path.
function borderRuns(outline) {
    const away = Math.max(0, outline.depth - borderInset);
    const points = outlinePoints(Object.assign({}, outline, {
        depth: away,
        start: outline.keepStart ? outline.start : outline.start + borderInset,
        end: outline.keepEnd ? outline.end : outline.end - borderInset
    }));
    const lay = item => laid(outline.barPosition, outline.boxDepth, item);
    const endRun = outline.keepEnd ? points.endSide.slice() : [points.end].concat(points.endSide);
    // The side away from the bar runs from the end of endSide back to the
    // start of startSide.
    const from = points.endSide[points.endSide.length - 1].along;
    const to = points.startSide[0].along;
    const gap = outline.gap;
    const gapStart = gap ? Math.max(to, gap.start) : 0;
    const gapEnd = gap ? Math.min(from, gap.end) : 0;
    let runs;

    if (!gap || gapEnd <= gapStart) {
        runs = [endRun.concat(points.startSide)];
    } else {
        if (gapEnd < from)
            endRun.push({ along: gapEnd, away: away });
        runs = [endRun, [{ along: gapStart, away: away }]
            .concat(gapStart > to ? points.startSide : points.startSide.slice(1))];
    }

    return runs.filter(run => run.length > 1).map(run => ({
        start: lay(run[0]),
        segments: run.slice(1).map(lay)
    }));
}

// What laidPath's segments are when neither end stays straight, in its order.
const attachedParts = ["barSide", "endJoin", "endSide", "endCorner", "farSide", "startCorner", "startSide",
    "startJoin"];

// An attached popup's outline. Takes { barPosition, width, height, unfolded,
// radius, joinRadius }, the surface's size and how far it has unfolded from the
// bar. Returns the box it fits in, relative to the surface,
// { x, y, width, height }, and in that box the path, as laidPath does, with its
// segments also by name in `parts`.
function attachedPath(surface) {
    const outline = attachedOutline(surface);
    const path = laidPath(outline);
    const parts = {};

    attachedParts.forEach((name, index) => parts[name] = path.segments[index]);

    return Object.assign({}, outline.box, {
        start: path.start,
        segments: path.segments,
        parts: parts
    });
}

// What the bar border of an attached popup's segments are, in order: its
// outline without the side against the bar.
const attachedBorderParts = attachedParts.slice(1);

// An attached popup's bar border. Takes attachedPath's surface. Returns the
// same box, and in it the border as one run, its segments also by name in
// `parts`.
function attachedBorder(surface) {
    const outline = attachedOutline(surface);
    const run = borderRuns(outline)[0];
    const parts = {};

    attachedBorderParts.forEach((name, index) => parts[name] = run.segments[index]);

    return Object.assign({}, outline.box, {
        start: run.start,
        segments: run.segments,
        parts: parts
    });
}

// An attached popup's outline as laidPath takes it, and the box it fits in,
// relative to the surface, as `box`.
function attachedOutline(surface) {
    const sideBar = BarPosition.sideBar(surface.barPosition);
    const length = sideBar ? surface.height : surface.width;
    const depth = Math.max(0, surface.unfolded);
    const boxDepth = Math.ceil(depth);
    const corners = attachedCorners({
        width: length,
        height: depth,
        radius: surface.radius,
        joinRadius: surface.joinRadius
    });
    const near = surface.joinRadius;
    const box = BarPosition.area(surface.barPosition, {
        along: -near,
        away: 0,
        length: length + near * 2,
        depth: boxDepth
    }, sideBar ? surface.width : surface.height);

    return {
        barPosition: surface.barPosition,
        depth: depth,
        boxDepth: boxDepth,
        start: near - corners.join,
        end: near + length + corners.join,
        corners: corners,
        box: box
    };
}

// A docked zone's outline as laidPath takes it. Takes dockedPath's zone.
function dockedOutline(zone) {
    return {
        barPosition: zone.barPosition,
        depth: zone.depth,
        boxDepth: zone.depth,
        start: 0,
        end: zone.length,
        corners: attachedCorners({
            width: zone.length,
            height: zone.depth,
            radius: zone.radius,
            joinRadius: zone.joinRadius
        }),
        keepStart: zone.keepStart,
        keepEnd: zone.keepEnd
    };
}

// A docked zone's outline, its joins inside it. Takes { barPosition, length,
// depth, radius, joinRadius, keepStart, keepEnd }: its size along and away from
// the bar, and which of its ends along the bar sit on the screen's edge and stay
// straight. Returns the path in the zone, as laidPath does.
function dockedPath(zone) {
    return laidPath(dockedOutline(zone));
}

// A docked zone's bar border, as borderRuns returns it. Takes dockedPath's zone
// and `gap`: the stretch { start, end } along the zone an attached popup hangs
// from, or null.
function dockedBorder(zone) {
    return borderRuns(Object.assign(dockedOutline(zone), { gap: zone.gap || null }));
}
