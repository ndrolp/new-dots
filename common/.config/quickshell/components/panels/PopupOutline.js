.pragma library
.import "PopupPlacement.js" as PopupPlacement

// The outline of an attached popup: square corners against the bar, small
// curved corners joining it to the bar, and rounded corners away from it.

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
    const unfolded = surface.unfolded;

    switch (surface.barPosition) {
    case "bottom":
        return { x: 0, y: surface.height - unfolded, width: surface.width, height: unfolded };
    case "left":
        return { x: 0, y: 0, width: unfolded, height: surface.height };
    case "right":
        return { x: surface.width - unfolded, y: 0, width: unfolded, height: surface.height };
    default:
        return { x: 0, y: 0, width: surface.width, height: unfolded };
    }
}

// The outline as a path. It is worked out for a bar on top, in `along` and
// `away` from the bar, then laid on the Bar position. Takes { barPosition,
// width, height, unfolded, radius, joinRadius }, the surface's size and how far
// it has unfolded from the bar. Returns the box it fits in, relative to the
// surface, { x, y, width, height }, and in that box the path's start { x, y }
// and its segments, in order: { x, y } lines and
// { x, y, controlX, controlY } curves.
function attachedPath(surface) {
    const side = PopupPlacement.vertical(surface.barPosition);
    const length = side ? surface.height : surface.width;
    const depth = Math.max(0, surface.unfolded);
    const boxDepth = Math.ceil(depth);
    const boxLength = length + surface.joinRadius * 2;
    const corners = attachedCorners({
        width: length,
        height: depth,
        radius: surface.radius,
        joinRadius: surface.joinRadius
    });
    const near = surface.joinRadius;
    const far = near + length;

    function point(along, away) {
        switch (surface.barPosition) {
        case "bottom":
            return { x: along, y: boxDepth - away };
        case "left":
            return { x: away, y: along };
        case "right":
            return { x: boxDepth - away, y: along };
        default:
            return { x: along, y: away };
        }
    }

    function curve(along, away, controlAlong, controlAway) {
        const end = point(along, away);
        const control = point(controlAlong, controlAway);

        return { x: end.x, y: end.y, controlX: control.x, controlY: control.y };
    }

    const box = {
        top: { x: -near, y: 0 },
        bottom: { x: -near, y: surface.height - boxDepth },
        left: { x: 0, y: -near },
        right: { x: surface.width - boxDepth, y: -near }
    }[surface.barPosition];

    return {
        x: box.x,
        y: box.y,
        width: side ? boxDepth : boxLength,
        height: side ? boxLength : boxDepth,
        start: point(near - corners.join, 0),
        segments: [
            point(far + corners.join, 0),
            curve(far, corners.join, far, 0),
            point(far, depth - corners.bottom),
            curve(far - corners.bottom, depth, far, depth),
            point(near + corners.bottom, depth),
            curve(near, depth - corners.bottom, near, depth),
            point(near, corners.join),
            curve(near - corners.join, 0, near, 0)
        ]
    };
}
