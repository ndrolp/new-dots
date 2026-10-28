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
    frame: 50
};

// How every animation eases: QtQuick's Easing.OutCubic (QEasingCurve's
// enum value, since a .pragma library can't read QtQuick's Easing).
const easing = 6;

// The motion to animate with: the durations above (reduce motion makes every
// animation instant, and changes still land because a 0 ms animation jumps to
// its end) and `easing`, the easing.type every animation uses.
function motion(reduceMotion) {
    const result = { easing: easing };
    for (const name in normal)
        result[name] = reduceMotion ? 0 : normal[name];
    return result;
}
