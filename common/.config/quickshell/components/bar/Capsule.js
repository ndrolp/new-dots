.pragma library
.import "../BarPosition.js" as BarPosition
.import "../../config/BarProfileModel.js" as BarProfileModel

// The capsule bar style: a single centred capsule instead of the bar. Pure
// functions over the bar profile of its monitor; they never mutate it.

// The bar elements a collapsed capsule shows, when the profile enables them,
// for a profile that never chose its own (see capsuleElements).
const collapsedElementIds = BarProfileModel.defaultProfile.capsuleElements;

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

// The bar elements a bar window draws: on a capsule, the collapsed row of the
// elements its profile chose (`capsuleElements`, else the default ones); the
// profile's own on any other bar style. Takes { barStyle, barElements,
// capsuleElements }.
function drawnElements(bar) {
    return bar.barStyle === "capsule"
        ? collapsedRow(bar.barElements, bar.capsuleElements || collapsedElementIds)
        : bar.barElements;
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
