.pragma library

// Which popup is open, and on which bar (its panel window): at most one at a
// time across every monitor.

var none = Object.freeze({ popup: "", window: null });

function isOpen(open, popup, window) {
    return open.popup === popup && open.window === window;
}

// A bar element was clicked: its popup opens, or closes if it was the open one.
function requested(open, popup, window) {
    return isOpen(open, popup, window) ? none : { popup: popup, window: window };
}

// A popup closed itself (it lost focus). Only the open one counts; one that
// was already replaced changes nothing.
function closed(open, popup, window) {
    return isOpen(open, popup, window) ? none : open;
}
