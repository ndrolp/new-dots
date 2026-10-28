.pragma library

// How long the shell's animations take, in ms. Every animation reads one of
// these instead of its own number, so reduce motion reaches all of them.
// Pure, no Quickshell.

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

// The durations to animate with: reduce motion makes every animation instant,
// and changes still land because a 0 ms animation jumps to its end.
function durations(reduceMotion) {
    const result = {};
    for (const name in normal)
        result[name] = reduceMotion ? 0 : normal[name];
    return result;
}
