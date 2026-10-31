.pragma library

// What a notification card does when it is tapped or swiped. Pure, no
// Quickshell.

// How far, as a share of the card's width, a sideways swipe has to go before
// letting go dismisses the card; a shorter one snaps it back.
var swipeThreshold = 0.35;

// Whether letting go of a card dragged `offset` px sideways dismisses it.
function swipeDismisses(offset, width) {
    return width > 0 && Math.abs(offset) >= width * swipeThreshold;
}

// The actions shown as buttons: all but the default one, which a tap runs.
function buttonActions(actions) {
    return (actions || []).filter(action => action.identifier !== "default");
}

// The action a tap runs: the notification's default action, or null when it
// has none (the card then expands instead).
function defaultAction(actions) {
    return (actions || []).find(action => action.identifier === "default") || null;
}
