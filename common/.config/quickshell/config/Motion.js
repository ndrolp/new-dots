.pragma library

// How the shell's animations move: how long they take, in ms, and how they
// ease. Every animation reads these instead of its own numbers, so reduce
// motion reaches all of them. Pure, no Quickshell.

const normal = {
    // Something leaving before its replacement slides in.
    brief: 90,
    // Hover and colour changes.
    short: 140,
    // Sizes and positions.
    medium: 180,
    // The bar's background and elements moving across it.
    long: 220,
    // Smoothing between two frames the Cava bar element draws.
    frame: 50,
    // How often the media live element's equaliser steps, when cava can't
    // run (components/bar/MediaLiveBars.qml); 0 stops it.
    equaliser: 160
};

// The capsule's own motion (capsule bar style only; every other bar style and
// popups outside a capsule keep the durations above). Its size and shape move
// on springs: `expand` overshoots slightly and settles, `collapse` is a bit
// faster and doesn't bounce; each is { duration, easing, overshoot }, for a
// NumberAnimation's duration, easing.type and easing.overshoot (pick one with
// components/bar/CapsuleMotion.js spring). Its contents crossfade with a
// slight scale while the shape moves, both from the moment it starts: the
// outgoing fade and shrink to `contentsScale` in `contentsOut` ms; the
// incoming start at `contentsScale`, wait `contentsDelay` ms (a third of
// `expand`, see motion()) into the shape's motion, then fade and grow to 1 in
// `contentsIn` ms. See components/bar/CapsuleContentTransition.qml.
const capsule = {
    expand: { duration: 350, easing: 34 /* Easing.OutBack */, overshoot: 0.9 },
    collapse: { duration: 280, easing: 6 /* Easing.OutCubic */, overshoot: 0 },
    contentsOut: 110,
    contentsIn: 200,
    contentsScale: 0.95
};

// How every animation eases: QtQuick's Easing.OutCubic (QEasingCurve's
// enum value, since a .pragma library can't read QtQuick's Easing).
const easing = 6;

// The motion to animate with: the durations above (reduce motion makes every
// animation instant, and changes still land because a 0 ms animation jumps to
// its end), `easing`, the easing.type every animation uses, and `capsule`,
// the capsule's springs and contents timing (instant too with reduce motion).
function motion(reduceMotion) {
    const result = { easing: easing };
    for (const name in normal)
        result[name] = reduceMotion ? 0 : normal[name];
    const time = ms => reduceMotion ? 0 : ms;
    result.capsule = {
        expand: Object.assign({}, capsule.expand, { duration: time(capsule.expand.duration) }),
        collapse: Object.assign({}, capsule.collapse, { duration: time(capsule.collapse.duration) }),
        contentsOut: time(capsule.contentsOut),
        contentsDelay: time(Math.round(capsule.expand.duration / 3)),
        contentsIn: time(capsule.contentsIn),
        contentsScale: capsule.contentsScale
    };
    return result;
}
