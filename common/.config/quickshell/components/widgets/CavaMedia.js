.pragma library

// What the Cava desktop widget shows of the player it follows, as plain
// values so it can be tested without Mpris. `player` is a plain object:
// { exists, playing, stopped, position, length, lengthKnown }.

// The media info and the progress line stay while a track is paused; they go
// only when there's no player or it has stopped.
function infoShown(player) {
    return !!player && player.exists && !player.stopped;
}

// The played fraction of the track, from 0 to 1, or -1 when there is no
// track length to measure it against (a live stream, or no player).
function playedFraction(player) {
    if (!infoShown(player) || !player.lengthKnown || !(player.length > 0))
        return -1;
    return Math.min(1, Math.max(0, player.position / player.length));
}

// What the progress line shows: the played fraction, or -1 to hide it.
function lineProgress(style, player) {
    return style === "line" ? playedFraction(player) : -1;
}

// What the bars paint in the progress color: the played fraction while the
// track plays, or -1 to paint nothing. Paused, the bars fade out, and so does
// their progress.
function barsProgress(style, player) {
    return style === "bars" && player && player.playing ? playedFraction(player) : -1;
}

// Where the media info sits under the bars: with the widget's column.
function infoX(horizontal, areaWidth, infoWidth) {
    if (horizontal === "left")
        return 0;
    if (horizontal === "right")
        return areaWidth - infoWidth;
    return (areaWidth - infoWidth) / 2;
}
