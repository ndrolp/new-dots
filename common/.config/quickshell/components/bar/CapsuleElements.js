.pragma library
.import "../../config/BarProfileModel.js" as BarProfileModel

// The capsule bar style's bar elements: which ones a capsule draws, collapsed
// or expanded, and which a profile can choose for it. Pure functions over the
// bar profile of its monitor; they never mutate it.

// The bar elements a collapsed capsule shows, when the profile enables them,
// for a profile that never chose its own (see capsuleElements).
const collapsedElementIds = BarProfileModel.defaultProfile.capsuleElements;

// The live elements and the side of the workspace pills each sits on. A
// capsule never draws them in its row but beside its pills: collapsed only
// while active (the recording indicator while recording, media while a track
// plays, see hasMedia), expanded as on any other bar style.
const liveSides = Object.freeze({ media: "left", recording: "right" });
const liveElementIds = Object.keys(liveSides);

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

// The bar elements an expanded capsule shows in its row: every one the
// profile has but the workspaces, which the workspace row already shows, and
// the live elements, which sit beside it.
function expandedElementIds(barElements) {
    const ids = [];
    for (const zone of zoneNames)
        ((barElements || {})[zone] || []).forEach(element => {
            if (choosable(element.id))
                ids.push(element.id);
        });
    return ids;
}

// Whether a profile can choose the bar element `id` for its collapsed
// capsule: any but the workspaces, which the workspace row shows, and the
// live elements, which sit beside the workspace pills.
function choosable(id) {
    return id !== "workspaces" && liveElementIds.indexOf(id) === -1;
}

// The bar elements a bar window draws in its zones: on a capsule, the
// collapsed row of the elements its profile chose (`capsuleElements`, else
// the default ones; any it can't choose are ignored), or its expanded row
// while `expanded`, or none while it shows a `change` instead, never the live
// elements (see liveElements); the profile's own on any other bar style.
// Takes { barStyle, barElements, capsuleElements, expanded, change }.
function drawnElements(bar) {
    if (!BarProfileModel.capsule(bar))
        return bar.barElements;
    if (bar.change === true)
        return collapsedRow(bar.barElements, []);
    return collapsedRow(bar.barElements, bar.expanded
        ? expandedElementIds(bar.barElements)
        : (bar.capsuleElements || collapsedElementIds).filter(choosable));
}

// The live elements a capsule draws beside its workspace pills, by side,
// { left: [ids], right: [ids] }, in the profile's order: those its profile
// enables. None on any other bar style. Takes { barStyle, barElements }.
function liveElements(bar) {
    const sides = { left: [], right: [] };
    if (!BarProfileModel.capsule(bar))
        return sides;

    for (const zone of zoneNames)
        ((bar.barElements || {})[zone] || []).forEach(element => {
            if (element.enabled !== false && liveSides[element.id])
                sides[liveSides[element.id]].push(element.id);
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
