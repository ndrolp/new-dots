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

// The bar IPC opens popups on: the focused monitor's, or the first shown bar
// when that monitor's bar is hidden; null when no bar is shown.
// `bars` is [{ window, monitor (its description), visible }].
function focusedBar(bars, focusedMonitor) {
    const shown = bars.filter(bar => bar.visible);
    const focused = shown.find(bar => bar.monitor === focusedMonitor);
    const bar = focused || shown[0];
    return bar ? bar.window : null;
}

// IPC toggles a popup (e.g. `notifications toggle`): it opens on the focused
// bar, or closes if it was open there. Its element missing from that bar is
// fine: the popup then opens at the bar's edge (PopupPlacement.js).
function toggledOnFocusedBar(open, popup, bars, focusedMonitor) {
    const window = focusedBar(bars, focusedMonitor);
    return window === null ? open : requested(open, popup, window);
}

// Opens a popup on the focused bar (e.g. quick settings' control center
// button); one already open there stays open.
function openedOnFocusedBar(open, popup, bars, focusedMonitor) {
    const window = focusedBar(bars, focusedMonitor);
    if (window === null || isOpen(open, popup, window))
        return open;
    return { popup: popup, window: window };
}
