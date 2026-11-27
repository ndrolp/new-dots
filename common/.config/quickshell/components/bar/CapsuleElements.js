.pragma library
.import "../../config/BarProfileModel.js" as BarProfileModel
.import "LiveElements.js" as LiveElements

// The capsule bar style's bar elements: which ones a capsule draws, collapsed
// or expanded, in its row or beside its workspace pills. Pure functions over
// the bar profile of its monitor; they never mutate it.
//
// Each bar element has a collapsed place in the profile, `capsulePlaces`
// (see BarProfileModel.capsulePlacesFor): hidden, shown in the collapsed
// row, shown in the row only while on battery, live beside the pills, left
// or right, or live in the row (shown there only while active); a profile
// without them takes the default ones. A
// capsule never draws one live beside its pills in its row: see
// LiveElements.js for those.

const zoneNames = ["left", "center", "right"];

// The capsule's row: the profile's bar elements as one centre zone, in the
// profile's order (left, centre, right), with only `shownIds` enabled and
// `liveIds` the live elements. Every
// other element stays listed, switched off, with its options. Groups keep to
// the zone they were made in: a zone's first element never joins the zone
// before. A live element leaves its group, which carries on without it: when
// it starts the group, the element after it starts it instead.
// Returns new bar elements { left: [], center: [...], right: [] }.
function collapsedRow(barElements, shownIds, liveIds) {
    const live = liveIds || [];
    const center = [];

    for (const zone of zoneNames) {
        let startsGroup = true;
        ((barElements || {})[zone] || []).forEach(element => {
            const item = Object.assign({}, element, {
                enabled: element.enabled !== false && shownIds.indexOf(element.id) !== -1
            });
            if (startsGroup)
                item.joinPrevious = false;
            startsGroup = live.indexOf(element.id) !== -1 && item.joinPrevious !== true;
            center.push(item);
        });
    }

    return { left: [], center: center, right: [] };
}

// The bar elements a bar window draws in its zones: on a capsule, the
// collapsed row of the elements whose place is shown, on battery or live in
// the row (BarElementItems.itemVisible hides the last two off battery or
// while inactive), or while `expanded`
// every element but the live ones (the workspaces take no place: the
// workspace row shows them), or none while it shows a `change` instead,
// never the live elements (see LiveElements.liveElements); the profile's own on any
// other bar style. Expanded, the elements whose cards the capsule glance
// shows, `glance` (CapsuleGlance.leavingElements), leave the row. Takes
// { barStyle, barElements, capsulePlaces, expanded, change, glance }.
function drawnElements(bar) {
    if (!BarProfileModel.capsule(bar))
        return bar.barElements;
    const ids = BarProfileModel.capsulePlaceIds(bar.barElements, bar.capsulePlaces);
    const liveIds = LiveElements.ids(ids.live);
    if (bar.change === true)
        return collapsedRow(bar.barElements, [], liveIds);
    if (!bar.expanded)
        return collapsedRow(bar.barElements, ids.shown.concat(ids.onBattery, ids.liveRow), liveIds);
    const glance = bar.glance || [];
    return collapsedRow(bar.barElements,
        ids.hidden.concat(ids.shown, ids.onBattery, ids.liveRow).filter(id => glance.indexOf(id) === -1), liveIds);
}

// The bar elements a capsule shows in its collapsed row only while running
// on battery: those its profile enables and places on battery, in the
// profile's order. None on any other bar style. Takes { barStyle,
// barElements, capsulePlaces }.
function onBatteryElements(bar) {
    if (!BarProfileModel.capsule(bar))
        return [];

    return BarProfileModel.capsulePlaceIds(bar.barElements, bar.capsulePlaces).onBattery
        .filter(id => BarProfileModel.elementEnabled(bar.barElements, id));
}
