.pragma library
.import "../Clamp.js" as Clamp

// How the capsule moves (capsule bar style only), over the capsule motion
// config/Motion.js gives as `motion.capsule`. Pure, no Quickshell. The parts
// to build a capsule transition from:
// - spring(motion, from, to): the spring a size change takes, for the
//   NumberAnimation that moves it (CapsuleSurface.qml moves the capsule's
//   size, place and corner radius with it).
// - contents(motion, elapsed, incoming): how contents look `elapsed` ms
//   into a crossfade, { opacity, scale }, incoming or outgoing.
// - contentsLength(motion): how long a crossfade runs.
// - centreOut(count), entering(motion, elapsed, step, steps) and
//   entryLength(motion, steps): a row's elements entering one after another
//   as the capsule expands, instead of crossfading in. Whatever enters after
//   the row takes the steps after its last, counted in `steps`.
// CapsuleContentTransition.qml runs a keyed crossfade with these; a popup
// inside the capsule (components/panels/PopupSurface.qml) drives them from
// its reveal.

// The spring the capsule takes from size `from` to size `to` (each
// { width, height }): `expand`, overshooting slightly, when it grows either
// way; `collapse`, without bounce, when it shrinks or keeps its size.
// Returns { duration, easing, overshoot }.
function spring(motion, from, to) {
    const grows = to.width > from.width || to.height > from.height;
    return grows ? motion.capsule.expand : motion.capsule.collapse;
}

// How far along a stretch `elapsed` is, 0 to 1, easing out (cubic); a 0 ms
// stretch is done at once.
function eased(elapsed, length) {
    const t = length <= 0 ? 1 : Clamp.unit(elapsed / length);
    return 1 - Math.pow(1 - t, 3);
}

// How the capsule's contents look `elapsed` ms into a crossfade, counted
// from when the shape starts moving, { opacity, scale }. Incoming, they wait
// `contentsDelay` (a third of the shape's spring) at `contentsScale` and
// transparent, then fade and grow to 1 over `contentsIn`. Outgoing, they fade
// and shrink to `contentsScale` over `contentsOut`, starting at once.
function contents(motion, elapsed, incoming) {
    const capsule = motion.capsule;
    const shrink = 1 - capsule.contentsScale;
    if (incoming) {
        const t = eased(elapsed - capsule.contentsDelay, capsule.contentsIn);
        return { opacity: t, scale: capsule.contentsScale + shrink * t };
    }
    const t = eased(elapsed, capsule.contentsOut);
    return { opacity: 1 - t, scale: 1 - shrink * t };
}

// How long, in ms, a crossfade runs: both halves start together, as the
// shape starts moving, and it ends once the incoming contents are fully in.
function contentsLength(motion) {
    const capsule = motion.capsule;
    return Math.max(capsule.contentsOut, capsule.contentsDelay + capsule.contentsIn);
}

// The order a row of `count` items enters in, expanding, from the centre
// outwards: for each item, left to right, its `step` (0 for the middle one,
// or both middle ones in an even row, then 1 for the pair either side of
// them…) and the `side` it slides out to its place from: 1 for an item left
// of the centre (it starts to the right), -1 right of it, 0 for the very
// centre, which fades in place. Returns [{ step, side }].
function centreOut(count) {
    const centre = (count - 1) / 2;
    const order = [];
    for (let index = 0; index < count; index++) {
        const away = index - centre;
        order.push({ step: Math.floor(Math.abs(away)), side: away < 0 ? 1 : away > 0 ? -1 : 0 });
    }
    return order;
}

// How long, in ms, each of `steps` steps takes to enter: so the last one is
// in as the expanding spring settles, but never less than `entryMin`.
function entryStepLength(motion, steps) {
    const capsule = motion.capsule;
    return Math.max(capsule.expand.duration - (steps - 1) * capsule.entryStep, capsule.entryMin);
}

// How step `step` of `steps` looks `elapsed` ms into an entry, counted from
// when the shape starts moving, { opacity, slide }: it waits `entryStep` ms
// per step before it, transparent and `entrySlide` px from its place (on the
// side centreOut gives it), then fades in and slides there, easing out.
function entering(motion, elapsed, step, steps) {
    const capsule = motion.capsule;
    const t = eased(elapsed - step * capsule.entryStep, entryStepLength(motion, steps));
    return { opacity: t, slide: capsule.entrySlide * (1 - t) };
}

// How long, in ms, an entry of `steps` steps runs: until its last step is
// in, and at least as long as a crossfade.
function entryLength(motion, steps) {
    const capsule = motion.capsule;
    const last = Math.max(steps - 1, 0) * capsule.entryStep + entryStepLength(motion, steps);
    return Math.max(contentsLength(motion), last);
}

// How a row's elements enter, from `positions`, each one's { start } along
// the row by element id (BarLayout.zone's positions): { steps, places }, how
// many steps the entry takes and each element's centreOut { step, side }, by
// id, in the order they start along the row.
function rowEntry(positions) {
    const ids = Object.keys(positions).sort((a, b) => positions[a].start - positions[b].start);
    const order = centreOut(ids.length);
    const places = {};
    ids.forEach((id, index) => places[id] = order[index]);
    return { steps: ids.length === 0 ? 0 : order[0].step + 1, places: places };
}

// How `element` in a capsule's row looks, { opacity, scale, slide }, from
// `row`: { entering, elapsed, entry, crossfade }. While the row `entering`
// (expanding), an element in its `entry` (rowEntry) looks as its step does
// `elapsed` ms in, unscaled, `slide` px to the side it comes from along the
// row; otherwise it takes the `crossfade`'s look, { opacity, scale }
// (contents), in place.
function rowLook(motion, row, element) {
    const place = row.entering ? row.entry.places[element] : undefined;
    if (place === undefined)
        return { opacity: row.crossfade.opacity, scale: row.crossfade.scale, slide: 0 };
    const look = entering(motion, row.elapsed, place.step, row.entry.steps);
    return { opacity: look.opacity, scale: 1, slide: look.slide * place.side };
}
