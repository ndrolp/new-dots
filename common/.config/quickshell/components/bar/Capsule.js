.pragma library
.import "../BarPosition.js" as BarPosition
.import "../../config/BarProfileModel.js" as BarProfileModel

// The capsule bar style: a single centred capsule instead of the bar. Pure
// functions over the bar profile of its monitor; they never mutate it.

// The bar elements a collapsed capsule shows, when the profile enables them,
// for a profile that never chose its own (see capsuleElements).
const collapsedElementIds = BarProfileModel.defaultProfile.capsuleElements;

// The live bar elements: a collapsed capsule also draws them, in the
// profile's order, but they show only while active: the recording indicator
// while recording, media while a track plays (see hasMedia).
const liveElementIds = ["recording", "media"];

const zoneNames = ["left", "center", "right"];

// The capsule's row: the profile's bar elements as one centre zone, in the
// profile's order (left, centre, right), with only `shownIds` enabled. Every
// other element stays listed, switched off, with its options. Groups keep to
// the zone they were made in: a zone's first element never joins the zone
// before. Returns new bar elements { left: [], center: [...], right: [] }.
function collapsedRow(barElements, shownIds) {
    const center = [];

    for (const zone of zoneNames) {
        ((barElements || {})[zone] || []).forEach((element, index) => {
            const item = Object.assign({}, element, {
                enabled: element.enabled !== false && shownIds.indexOf(element.id) !== -1
            });
            if (index === 0)
                item.joinPrevious = false;
            center.push(item);
        });
    }

    return { left: [], center: center, right: [] };
}

// The bar elements an expanded capsule shows: every one the profile has but
// the workspaces, which the workspace row already shows.
function expandedElementIds(barElements) {
    const ids = [];
    for (const zone of zoneNames)
        ((barElements || {})[zone] || []).forEach(element => {
            if (element.id !== "workspaces")
                ids.push(element.id);
        });
    return ids;
}

// The bar elements a bar window draws: on a capsule, the collapsed row of the
// elements its profile chose (`capsuleElements`, else the default ones), live
// bar elements included, or its expanded row while `expanded`; the profile's
// own on any other bar style. Takes { barStyle, barElements, capsuleElements,
// expanded }.
function drawnElements(bar) {
    if (bar.barStyle !== "capsule")
        return bar.barElements;
    return collapsedRow(bar.barElements, bar.expanded
        ? expandedElementIds(bar.barElements)
        : (bar.capsuleElements || collapsedElementIds).concat(liveElementIds));
}

// Whether the capsule is expanded: while any of its causes holds it, given as
// { cause: bool }. Hovering it is one ("hover"); others join as more keys.
function expanded(causes) {
    return Object.keys(causes || {}).some(cause => causes[cause] === true);
}

// Whether `point` { x, y } is over the capsule `place` (as Capsule.surface
// gives it, or null when there is no capsule), in the bar content.
function contains(place, point) {
    return !!place && point.x >= place.x && point.x < place.x + place.width
        && point.y >= place.y && point.y < place.y + place.height;
}

// Whether media has something to show, given the bar style and the Mpris
// player it follows (null without one): on a collapsed capsule only while a
// track plays, on an `expanded` one or any other bar style while there is a
// player at all.
function hasMedia(barStyle, player, expanded) {
    if (!player)
        return false;
    return barStyle !== "capsule" || expanded === true || player.isPlaying === true;
}

// Where the capsule is drawn in the bar content, { x, y, width, height,
// radius }: around its row's { start, end } along the bar, with `padding` at
// both ends, as deep as the content and with fully round ends. Takes the bar
// content as BarLayout measures it, { barPosition, width, height }. With
// nothing in the row there is no capsule: it has no size.
function surface(content, span, padding) {
    if (span.end <= span.start)
        return { x: span.start, y: 0, width: 0, height: 0, radius: 0 };

    const sideBar = BarPosition.sideBar(content.barPosition);
    const depth = sideBar ? content.width : content.height;
    const rect = BarPosition.area(content.barPosition, {
        along: span.start - padding,
        away: 0,
        length: span.end - span.start + padding * 2,
        depth: depth
    }, depth);

    return Object.assign(rect, { radius: depth / 2 });
}

// The part of the bar window that takes clicks, { x, y, width, height }: only
// the capsule, so clicks around it reach the windows below. Takes the
// capsule's surface and the margins { top, right, bottom, left } the bar
// content keeps in the window.
function inputRegion(surface, margins) {
    return {
        x: margins.left + surface.x,
        y: margins.top + surface.y,
        width: surface.width,
        height: surface.height
    };
}
