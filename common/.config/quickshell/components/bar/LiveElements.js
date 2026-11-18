.pragma library
.import "../../config/BarProfileModel.js" as BarProfileModel
.import "BarLayout.js" as BarLayout

// A capsule's live elements (see GLOSSARY.md): which of its bar elements it
// draws beside its workspace pills, on which side, when each has something
// to show there and how large it is drawn. Pure functions over the bar
// profile of its monitor; they never mutate it. A live element is drawn
// collapsed only while active (see activeRules), expanded as on any other
// bar style.

// The live elements a capsule draws beside its workspace pills, by side,
// { left: [ids], right: [ids] }, in the profile's order: those its profile
// enables and places live on that side. None on any other bar style. Takes
// { barStyle, barElements, capsulePlaces }.
function liveElements(bar) {
    if (!BarProfileModel.capsule(bar))
        return { left: [], right: [] };

    const live = BarProfileModel.capsulePlaceIds(bar.barElements, bar.capsulePlaces).live;
    const enabled = id => BarProfileModel.elementEnabled(bar.barElements, id);
    return { left: live.left.filter(enabled), right: live.right.filter(enabled) };
}

// The ids of the live elements by side, `sides` as liveElements gives them
// (or null for none), as one list: the left ones, then the right ones.
function ids(sides) {
    return sides ? sides.left.concat(sides.right) : [];
}

// When each bar element that can be live (BarProfileModel.liveElementIds) is
// active, by id: what a collapsed capsule shows it beside its pills for.
// Each rule takes what there is to show, { player (the Mpris player media
// follows, or null), recordings (RecordingIndicator.recordings), keepAwakeOn }.
// A new live element needs its rule here and its id in liveElementIds.
const activeRules = Object.freeze({
    recording: status => status.recordings.length > 0,
    media: status => !!status.player && status.player.isPlaying === true,
    keepAwake: status => status.keepAwakeOn === true
});

// Whether bar element `id` is active, given what there is to show (see
// activeRules); never for one that can't be live.
function active(id, status) {
    const rule = activeRules[id];
    return rule !== undefined && rule(status);
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
