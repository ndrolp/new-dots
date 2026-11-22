.pragma library

// What media players do, without Quickshell: which one the control
// center's media card follows, what a scroll over the bar's media element
// skips to, the colour a capsule's media view takes from the art and what
// moves the media live element's bars.

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

// The one colour the media view inside a capsule tints its progress bar, play
// button and the glow behind the art with: one of `artColors` (what
// Quickshell's ColorQuantizer found in the art, each with r, g, b from 0 to
// 1) while the art shows (`artShown`), or else `accent`. Of the art's colours
// it is the most colourful (the widest spread between its channels), so a
// cover's greys and shadows don't win over its colour.
function artTint(artColors, artShown, accent) {
    if (!artShown || !artColors || artColors.length === 0)
        return accent;
    const spread = color => Math.max(color.r, color.g, color.b) - Math.min(color.r, color.g, color.b);
    let best = artColors[0];
    for (let index = 1; index < artColors.length; index++) {
        if (spread(artColors[index]) > spread(best))
            best = artColors[index];
    }
    return best;
}

// What moves the bars of the media live element at rest, { source, moving }:
// the shared cava's frame ("cava") while it works, that is while it has no
// `cavaFailureHint` (services/Cava.qml), or else a simple animated equaliser
// ("equaliser"). They move only while the player is `playing`.
function liveBars(playing, cavaFailureHint) {
    return { source: cavaFailureHint ? "equaliser" : "cava", moving: playing === true };
}

// The equaliser's frame at `step` (it steps on a timer while it moves):
// `barCount` heights from 0.2 to 0.9, each bar bobbing on waves of its own
// speed, so they look like music without hearing any. The same step always
// gives the same frame.
function equaliserFrame(barCount, step) {
    const heights = [];
    for (let index = 0; index < barCount; index++) {
        const wave = Math.sin(step * (0.9 + index * 0.37) + index * 1.7)
            + Math.sin(step * (0.5 + index * 0.23) + index * 2.9);
        heights.push(0.55 + 0.35 * wave / 2);
    }
    return heights;
}
