.pragma library
.import "../BarPosition.js" as BarPosition
.import "BarPlacement.js" as BarPlacement
.import "../../config/BarProfileModel.js" as BarProfileModel

// Where the capsule bar style's capsule sits: its surface in the bar content,
// grown round a popup inside, the part of its window that takes clicks and
// its workspace pills. Pure functions; they never mutate what they are given.

// Where the capsule is drawn in the bar content, { x, y, width, height,
// radius }: around its row's { start, end } along the bar, with `padding` at
// both ends, as deep as the content and `strip` past it, away from the screen
// edge, for its workspace pills (BarPlacement.workspaceStrip), and with fully
// round ends. Takes the bar content as BarLayout measures it,
// { barPosition, width, height }. With nothing in the row there is no
// capsule: it has no size.
function surface(content, span, padding, strip) {
    if (span.end <= span.start)
        return { x: span.start, y: 0, width: 0, height: 0, radius: 0 };

    const sideBar = BarPosition.sideBar(content.barPosition);
    const depth = sideBar ? content.width : content.height;
    const reach = depth + (strip || 0);
    const rect = BarPosition.area(content.barPosition, {
        along: span.start - padding,
        away: 0,
        length: span.end - span.start + padding * 2,
        depth: reach
    }, depth);

    return Object.assign(rect, { radius: reach / 2 });
}

// The capsule with a popup inside, { x, y, width, height, radius }: its row's
// `place` (as surface gives it) grown to the wider of the row and the popup,
// staying centred on the row, and as deep as the row and the popup together,
// away from the screen edge at `barPosition` ("top" or "bottom"). Takes the
// popup's { width, height }, or null without one, when it is just its row.
function withPopup(place, popup, barPosition) {
    if (!popup)
        return place;

    const width = Math.max(place.width, popup.width);
    return {
        x: place.x + (place.width - width) / 2,
        y: barPosition === "bottom" ? place.y - popup.height : place.y,
        width: width,
        height: place.height + popup.height,
        radius: place.radius
    };
}

// The part of the bar window that takes clicks, { x, y, width, height }: only
// the capsule, so clicks around it reach the windows below. Takes the
// capsule's surface and where the bar content starts in the window,
// { top, left }.
function inputRegion(surface, margins) {
    return {
        x: margins.left + surface.x,
        y: margins.top + surface.y,
        width: surface.width,
        height: surface.height
    };
}

// Where the capsule's workspace pills sit in the bar content,
// { centre, y }: inside the capsule, centred on it along the bar, just past
// its row of bar elements, so under the row of a top capsule and above the
// row of a bottom one. Takes the bar content, { barPosition, height }, and
// the capsule as surface gives it, or null; null with no capsule drawn.
function workspacePills(content, capsule) {
    if (!capsule || capsule.width <= 0)
        return null;

    return {
        centre: capsule.x + capsule.width / 2,
        y: content.barPosition === "bottom" ? -BarPlacement.workspacePillDepth : content.height
    };
}

// Whether `point` { x, y } is over the capsule `place` (as surface
// gives it, or null when there is no capsule), in the bar content.
function contains(place, point) {
    return !!place && point.x >= place.x && point.x < place.x + place.width
        && point.y >= place.y && point.y < place.y + place.height;
}
