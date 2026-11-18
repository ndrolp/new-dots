.pragma library
.import "../../config/BarProfileModel.js" as BarProfileModel
.import "BarLayout.js" as BarLayout

// A capsule's live elements (see GLOSSARY.md): which of its bar elements it
// draws beside its workspace pills, on which side, when each has something
// to show there and how large it is drawn. Pure functions over the bar
// profile of its monitor; they never mutate it. A live element is drawn
// collapsed only while active (the recording indicator while recording,
// media while a track plays, see hasMedia, keep-awake while on, see
// hasKeepAwake), expanded as on any other bar style.

const zoneNames = ["left", "center", "right"];

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

// Whether keep-awake has something to show, given a capsule's live elements
// by side, { left, right } (see liveElements; none on any other bar style),
// and whether keep-awake is `on`: always, off too, but as a live element of
// a collapsed capsule only while it is on; an `expanded` capsule shows it as
// any other bar style does.
function hasKeepAwake(live, on, expanded) {
    const ids = live ? live.left.concat(live.right) : [];
    return ids.indexOf("keepAwake") === -1 || expanded === true || on === true;
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
