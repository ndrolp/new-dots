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

// How long a new notification's card shows, as a toast or inside the
// capsule, in ms: the timeout its app asks for, else 5 s; 0 for a critical
// one, which stays until it is dismissed. `notification` is
// { expireTimeout, critical }.
function toastTimeout(notification) {
    if (notification.critical === true)
        return 0;
    return notification.expireTimeout > 0 ? notification.expireTimeout : 5000;
}
