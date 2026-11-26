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
// edge, for its workspace pills (BarPlacement.workspaceStrip), `across` more
// on both sides for its vertical padding (BarPlacement.capsulePadding), and
// with fully round ends. Takes the bar content as BarLayout measures it,
// { barPosition, width, height }. With nothing in the row there is no
// capsule: it has no size.
function surface(content, span, padding, strip, across) {
    if (span.end <= span.start)
        return { x: span.start, y: 0, width: 0, height: 0, radius: 0 };

    const sideBar = BarPosition.sideBar(content.barPosition);
    const depth = sideBar ? content.width : content.height;
    const room = across || 0;
    const reach = depth + (strip || 0) + room * 2;
    const rect = BarPosition.area(content.barPosition, {
        along: span.start - padding,
        away: -room,
        length: span.end - span.start + padding * 2,
        depth: reach
    }, depth);

    return Object.assign(rect, { radius: reach / 2 });
}

// How round a capsule's corners are with something inside past its row: a
// rounded rectangle, not a pill, concentric with a popup's own 8 px corners
// inset by its 12 px padding (PopupSurface.qml).
const popupCornerRadius = 20;

// The capsule with something `inside` it past its row (a popup inside, the
// capsule glance), { x, y, width, height, radius }: its row's `place` (as
// surface gives it) grown to the wider of the row and what is inside,
// staying centred on the row, and as deep as the two together, away from the
// screen edge at `barPosition` ("top" or "bottom"), with its corners down to
// popupCornerRadius (never rounder than the row's). Takes what is inside as
// { width, height }, or null with nothing, when it is just its row.
function withInside(place, inside, barPosition) {
    if (!inside)
        return place;

    const width = Math.max(place.width, inside.width);
    return {
        x: place.x + (place.width - width) / 2,
        y: barPosition === "bottom" ? place.y - inside.height : place.y,
        width: width,
        height: place.height + inside.height,
        radius: Math.min(place.radius, popupCornerRadius)
    };
}

// Where the capsule glance goes in the bar content, { x, y }: where a popup
// inside would, centred on its row's `place` (as surface gives it) and just
// past it, away from the screen edge at `barPosition` ("top" or "bottom").
// Takes the glance's { width, height }; withInside grows the capsule round it.
function glancePlace(place, glance, barPosition) {
    return {
        x: place.x + (place.width - glance.width) / 2,
        y: barPosition === "bottom" ? place.y - glance.height : place.y + place.height
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

// Where the capsule's pill row goes in the bar content: its workspace pills
// with its live elements beside them, left and right, `spacing` apart, the
// lot centred along the bar on `centre`, the centre of its row of bar
// elements. The row sits just past that row of bar elements, so under the
// row of a top capsule and above the row of a bottom one, as deep as the
// deepest of the pills and the live elements shown; each is centred across
// it. A live element not `shown` takes no room: it waits just outside its
// side of what is shown, to fade there.
// Takes the bar content, { barPosition, height }, and { centre, spacing,
// pills (their length), pillDepth (their depth: the pills' at rest, the
// chips' expanded), left, right }, each side a list of live elements
// { id, length, depth, shown } from the pills outwards for the right and
// inwards for the left. Returns { start, end, depth, pills: { x, y },
// elements: { id: { x, y } } }.
function pillRow(content, given) {
    const pillDepth = given.pillDepth;
    const shown = given.left.concat(given.right).filter(element => element.shown);
    const depth = Math.max(pillDepth, ...shown.map(element => element.depth));
    const length = shown.reduce((total, element) => total + element.length + given.spacing, given.pills);
    const away = content.barPosition === "bottom" ? -depth : content.height;
    const across = itemDepth => away + (depth - itemDepth) / 2;
    const elements = {};
    let along = given.centre - length / 2;

    const place = element => {
        elements[element.id] = { x: along, y: across(element.depth) };
        along += element.length + given.spacing;
    };
    const wait = (element, x) => elements[element.id] = { x: x, y: across(element.depth) };

    given.left.forEach(element => element.shown ? place(element)
        : wait(element, along - given.spacing - element.length));
    const pills = { x: along, y: across(pillDepth) };
    along += given.pills;
    given.right.forEach(element => {
        if (element.shown) {
            along += given.spacing;
            elements[element.id] = { x: along, y: across(element.depth) };
            along += element.length;
        } else {
            wait(element, along + given.spacing);
        }
    });

    return {
        start: given.centre - length / 2,
        end: given.centre + length / 2,
        depth: depth,
        pills: pills,
        elements: elements
    };
}

// The capsule's span along the bar, { start, end }: round its row of bar
// elements, `row`, and its pill row, `pills`, as pillRow gives it. With
// nothing in its row, it is its pill row's: the pills and any live elements
// they show.
function span(row, pills) {
    if (row.end <= row.start)
        return { start: pills.start, end: pills.end };
    return { start: Math.min(row.start, pills.start), end: Math.max(row.end, pills.end) };
}

// Whether `point` { x, y } is over the capsule `place` (as surface
// gives it, or null when there is no capsule), in the bar content.
function contains(place, point) {
    return !!place && point.x >= place.x && point.x < place.x + place.width
        && point.y >= place.y && point.y < place.y + place.height;
}
