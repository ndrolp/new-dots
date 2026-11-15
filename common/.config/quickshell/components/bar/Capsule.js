.pragma library
.import "../BarPosition.js" as BarPosition
.import "BarPlacement.js" as BarPlacement
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
// bar elements included, or its expanded row while `expanded`, or none while
// it shows a `change` instead; the profile's own on any other bar style.
// Takes { barStyle, barElements, capsuleElements, expanded, change }.
function drawnElements(bar) {
    if (bar.barStyle !== "capsule")
        return bar.barElements;
    if (bar.change === true)
        return collapsedRow(bar.barElements, []);
    return collapsedRow(bar.barElements, bar.expanded
        ? expandedElementIds(bar.barElements)
        : (bar.capsuleElements || collapsedElementIds).concat(liveElementIds));
}

// Whether the capsule is expanded: while any of its causes holds it, given as
// { cause: bool }. Hovering it is one ("hover"); others join as more keys.
function expanded(causes) {
    return Object.keys(causes || {}).some(cause => causes[cause] === true);
}

// The bar window SUPER+I expands or collapses: the focused monitor's, when it
// is shown and is a capsule; else null, and the toggle does nothing. `bars`
// are { window, monitor, visible, capsule }, as modules/Bar.qml lists them.
function toggledBar(bars, focusedMonitor) {
    const bar = (bars || []).find(bar => bar.monitor === focusedMonitor);
    return bar && bar.visible && bar.capsule ? bar.window : null;
}

// Where a change (volume, brightness, Caps Lock, audio output, bar profile or
// keep-awake) shows, on the focused monitor only: { capsule: window } when it
// has a capsule shown, which expands to show it instead of the OSD; {} while a
// popup is inside that capsule, when it shows nowhere; else { osd: screen },
// the OSD on the focused monitor's screen, or on the first screen (null) when
// no bar is on it. `bars` are { window, monitor, screen, visible, capsule,
// popupInside }, as modules/Bar.qml lists them.
function changeTarget(bars, focusedMonitor) {
    const bar = (bars || []).find(bar => bar.monitor === focusedMonitor);
    if (!bar)
        return { osd: null };
    if (!bar.visible || !bar.capsule)
        return { osd: bar.screen };
    return bar.popupInside ? {} : { capsule: bar.window };
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

// Where the capsule's workspace row sits: in a window of its own on the
// capsule's screen edge, running the length of the screen. That window keeps
// clear of what the capsule reserves, so `margin`, the profile's spacing, is
// its gap from the capsule: it is under a top capsule and above a bottom one.
// Its pills are centred on `centre`, the capsule's centre along the bar.
// Takes the bar profile, { barStyle, barPosition, spacing }, and the capsule
// in its bar window, { x, y, width, height } (see inputRegion). Returns
// { anchors: { top, right, bottom, left }, margin, centre }, or null on any
// other bar style or with no capsule drawn.
function workspaceRow(bar, capsule) {
    if (bar.barStyle !== "capsule" || capsule.width <= 0)
        return null;

    return {
        anchors: BarPlacement.windowAnchors(bar.barPosition),
        margin: bar.spacing,
        centre: capsule.x + capsule.width / 2
    };
}
