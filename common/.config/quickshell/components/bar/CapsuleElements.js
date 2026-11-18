.pragma library
.import "../../config/BarProfileModel.js" as BarProfileModel
.import "BarLayout.js" as BarLayout

// The capsule bar style's bar elements: which ones a capsule draws, collapsed
// or expanded, in its row or beside its workspace pills. Pure functions over
// the bar profile of its monitor; they never mutate it.
//
// Each bar element has a collapsed place in the profile, `capsulePlaces`
// (see BarProfileModel.capsulePlacesFor): hidden, shown in the collapsed
// row, or live beside the pills, left or right; a profile without them takes
// the default ones. A capsule never draws a live one in its row but beside
// its pills: collapsed only while active (the recording indicator while
// recording, media while a track plays, see hasMedia), expanded as on any
// other bar style.

// The ids with each collapsed place, { place: [ids] }, from `capsulePlaces`.
function idsByPlace(capsulePlaces) {
    const places = BarProfileModel.completeCapsulePlaces(capsulePlaces);
    const ids = { hidden: [], shown: [], liveLeft: [], liveRight: [] };
    for (const id in places)
        ids[places[id]].push(id);
    return ids;
}

const zoneNames = ["left", "center", "right"];

// The capsule's row: the profile's bar elements as one centre zone, in the
// profile's order (left, centre, right), with only `shownIds` enabled. Every
// other element stays listed, switched off, with its options. Groups keep to
// the zone they were made in: a zone's first element never joins the zone
// before. A live element leaves its group, which carries on without it: when
// it starts the group, the element after it starts it instead.
// Returns new bar elements { left: [], center: [...], right: [] }.
function collapsedRow(barElements, shownIds) {
    const center = [];

    for (const zone of zoneNames) {
        let startsGroup = true;
        ((barElements || {})[zone] || []).forEach(element => {
            const item = Object.assign({}, element, {
                enabled: element.enabled !== false && shownIds.indexOf(element.id) !== -1
            });
            if (startsGroup)
                item.joinPrevious = false;
            startsGroup = liveSides[element.id] !== undefined && item.joinPrevious !== true;
            center.push(item);
        });
    }

    return { left: [], center: center, right: [] };
}

// The bar elements a bar window draws in its zones: on a capsule, the
// collapsed row of the elements whose place is shown, or while `expanded`
// every element but the live ones (the workspaces take no place: the
// workspace row shows them), or none while it shows a `change` instead,
// never the live elements (see liveElements); the profile's own on any
// other bar style. Takes { barStyle, barElements, capsulePlaces, expanded,
// change }.
function drawnElements(bar) {
    if (!BarProfileModel.capsule(bar))
        return bar.barElements;
    if (bar.change === true)
        return collapsedRow(bar.barElements, []);

    const ids = idsByPlace(bar.capsulePlaces);
    return collapsedRow(bar.barElements, bar.expanded ? ids.hidden.concat(ids.shown) : ids.shown);
}

// The live elements a capsule draws beside its workspace pills, by side,
// { left: [ids], right: [ids] }, in the profile's order: those its profile
// enables and places live on that side. None on any other bar style. Takes
// { barStyle, barElements, capsulePlaces }.
function liveElements(bar) {
    const sides = { left: [], right: [] };
    if (!BarProfileModel.capsule(bar))
        return sides;

    const places = BarProfileModel.completeCapsulePlaces(bar.capsulePlaces);
    for (const zone of zoneNames)
        ((bar.barElements || {})[zone] || []).forEach(element => {
            const side = BarProfileModel.liveSide(places[element.id]);
            if (element.enabled !== false && side !== "")
                sides[side].push(element.id);
        });
    return sides;
}

// Whether media has something to show, given the bar profile, { barStyle },
// and the Mpris player it follows (null without one): on a collapsed capsule
// only while a track plays, on an `expanded` one or any other bar style while
// there is a player at all.
function hasMedia(bar, player, expanded) {
    if (!player)
        return false;
    return !BarProfileModel.capsule(bar) || expanded === true || player.isPlaying === true;
}

// How large a live element is beside the workspace pills, as a share of the
// profile's sizes: smaller, with no setting of its own.
const liveScale = 0.8;

// The sizes a bar element is drawn at, { textSize, iconSize, thickness (its
// pill's, across the bar) }: the profile's, or a `live` element's beside a
// capsule's pills, liveScale of them in whole pixels.
function elementSizes(profile, live) {
    const scale = value => live ? Math.round(value * liveScale) : value;
    return {
        textSize: scale(profile.textSize),
        iconSize: scale(profile.iconSize),
        thickness: scale(BarLayout.elementThickness(profile))
    };
}
