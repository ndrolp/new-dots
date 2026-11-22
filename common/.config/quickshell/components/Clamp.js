.pragma library

// Holding a number in range. Pure, no Quickshell.

// `value` held between 0 and 1: a share, a level or how far along something
// is.
function unit(value) {
    return Math.max(0, Math.min(1, value));
}
