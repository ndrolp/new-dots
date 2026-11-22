.pragma library

// How the capsule moves (capsule bar style only), over the capsule motion
// config/Motion.js gives as `motion.capsule`. Pure, no Quickshell. The parts
// to build a capsule transition from:
// - spring(motion, from, to): the spring a size change takes, for the
//   NumberAnimation that moves it (CapsuleSurface.qml moves the capsule's
//   size, place and corner radius with it).
// - contents(motion, elapsed, incoming): how contents look `elapsed` ms
//   into a crossfade, { opacity, scale }, incoming or outgoing.
// - contentsLength(motion): how long a crossfade runs.
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
    const t = length <= 0 ? 1 : Math.max(0, Math.min(1, elapsed / length));
    return 1 - Math.pow(1 - t, 3);
}

// How the capsule's contents look `elapsed` ms into a crossfade, counted
// from when the shape starts moving, { opacity, scale }. Incoming, they wait `contentsDelay` (a third
// of the shape's spring) at `contentsScale` and transparent, then fade and
// grow to 1 over `contentsIn`. Outgoing, they fade and shrink to
// `contentsScale` over `contentsOut`, starting at once.
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
