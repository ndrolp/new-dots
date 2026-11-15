.pragma library
.import "../../config/BarProfileModel.js" as BarProfileModel

// The capsule bar style's bar elements: which ones a capsule draws, collapsed
// or expanded, and which a profile can choose for it. Pure functions over the
// bar profile of its monitor; they never mutate it.

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

// Whether a profile can choose the bar element `id` for its collapsed
// capsule: any but the workspaces, which the workspace row shows, and the
// live bar elements, which it always draws.
function choosable(id) {
    return id !== "workspaces" && liveElementIds.indexOf(id) === -1;
}

// The bar elements a bar window draws: on a capsule, the collapsed row of the
// elements its profile chose (`capsuleElements`, else the default ones; any
// it can't choose are ignored), live bar elements included, or its expanded row while `expanded`, or none while
// it shows a `change` instead; the profile's own on any other bar style.
// Takes { barStyle, barElements, capsuleElements, expanded, change }.
function drawnElements(bar) {
    if (!BarProfileModel.capsule(bar))
        return bar.barElements;
    if (bar.change === true)
        return collapsedRow(bar.barElements, []);
    return collapsedRow(bar.barElements, bar.expanded
        ? expandedElementIds(bar.barElements)
        : (bar.capsuleElements || collapsedElementIds).filter(choosable).concat(liveElementIds));
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
