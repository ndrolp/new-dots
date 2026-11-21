.pragma library

// What media players do, without Quickshell: which one the control
// center's media card follows and what a scroll over the bar's media element
// skips to.

// The player the control center's media card follows: the one playing, or
// else the first with a track loaded (paused). None of them (no player, or
// only idle ones with no track) hides the card.
function activePlayer(players) {
    return players.find(player => player.isPlaying)
        || players.find(player => !!player.trackTitle)
        || null;
}

// Scrolling over the bar's media element: a step (components/WheelSteps.js)
// forward skips the player it shows to the next track, one back to the
// previous one, where the player can.
function skipTrack(player, step) {
    if (!player)
        return;
    if (step > 0 && player.canGoNext)
        player.next();
    else if (step < 0 && player.canGoPrevious)
        player.previous();
}
