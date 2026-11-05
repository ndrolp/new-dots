.pragma library
.import "../BarPosition.js" as BarPosition

// The outline of an attached popup: square corners against the bar, small
// curved corners joining it to the bar, and rounded corners away from it. A
// zone of the docked bar has the same outline.

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

// The outline as a path, worked out for a bar on top, in `along` and `away` from
// the bar, then laid on the Bar position. Takes { barPosition, depth, boxDepth,
// start, end, corners, keepStart, keepEnd }: how far it reaches from the bar,
// the depth of the box it is laid in, where along the bar its joins start and
// end, its attachedCorners, and which ends stay straight instead of curving.
// Returns the path's start { x, y } and its segments, in order: { x, y } lines
// and { x, y, controlX, controlY } curves.
function laidPath(outline) {
    const depth = outline.depth;
    const start = outline.start;
    const end = outline.end;
    const join = outline.corners.join;
    const bottom = outline.corners.bottom;
    const near = start + join;
    const far = end - join;

    function point(along, away) {
        return BarPosition.point(outline.barPosition, along, away, outline.boxDepth);
    }

    function curve(along, away, controlAlong, controlAway) {
        const to = point(along, away);
        const control = point(controlAlong, controlAway);

        return { x: to.x, y: to.y, controlX: control.x, controlY: control.y };
    }

    const endSide = outline.keepEnd ? [point(end, depth)] : [
        curve(far, join, far, 0),
        point(far, depth - bottom),
        curve(far - bottom, depth, far, depth)
    ];
    const startSide = outline.keepStart ? [point(start, depth)] : [
        point(near + bottom, depth),
        curve(near, depth - bottom, near, depth),
        point(near, join),
        curve(start, 0, near, 0)
    ];

    return {
        start: point(start, 0),
        segments: [point(end, 0)].concat(endSide, startSide)
    };
}

// An attached popup's outline. Takes { barPosition, width, height, unfolded,
// radius, joinRadius }, the surface's size and how far it has unfolded from the
// bar. Returns the box it fits in, relative to the surface,
// { x, y, width, height }, and in that box the path, as laidPath does.
function attachedPath(surface) {
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
    const path = laidPath({
        barPosition: surface.barPosition,
        depth: depth,
        boxDepth: boxDepth,
        start: near - corners.join,
        end: near + length + corners.join,
        corners: corners
    });

    return {
        x: box.x,
        y: box.y,
        width: box.width,
        height: box.height,
        start: path.start,
        segments: path.segments
    };
}

// A docked zone's outline, its joins inside it. Takes { barPosition, length,
// depth, radius, joinRadius, keepStart, keepEnd }: its size along and away from
// the bar, and which of its ends along the bar sit on the screen's edge and stay
// straight. Returns the path in the zone, as laidPath does.
function dockedPath(zone) {
    return laidPath({
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
    });
}
