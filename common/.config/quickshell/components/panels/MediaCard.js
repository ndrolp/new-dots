.pragma library

// The player the control center's media card follows: the one playing, or
// else the first with a track loaded (paused). None of them (no player, or
// only idle ones with no track) hides the card.
function activePlayer(players) {
    return players.find(player => player.isPlaying)
        || players.find(player => !!player.trackTitle)
        || null;
}
