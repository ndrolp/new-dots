.pragma library

// What media players do, without Quickshell: which one the control
// center's media card follows, what a scroll over the bar's media element
// skips to, the colour a capsule's media view takes from the art (and where
// it reads that art from) and what moves the media live element's bars.

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

// The capsule glance's play/pause: plays or pauses `player`, where it can.
function togglePlaying(player) {
    if (player && player.canTogglePlaying)
        player.togglePlaying();
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

// How light a colour (r, g, b from 0 to 1) looks, 0 to 1 (Rec. 709 weights).
function lightness(color) {
    return 0.2126 * color.r + 0.7152 * color.g + 0.0722 * color.b;
}

// What reads on the tint (the play button's glyph): of `colours`' (Theme.qml)
// background and text, the one further from the tint in lightness, so on any
// colorscheme it is light on a dark tint and dark on a light one.
function onTint(tint, colours) {
    const fromTint = color => Math.abs(lightness(color) - lightness(tint));
    return fromTint(colours.background) > fromTint(colours.text) ? colours.background : colours.text;
}

// Where art fetched from the web is kept: quickshell/art under the user's
// cache, `xdgCacheHome` or else ~/.cache under `home`.
function artCacheDir(xdgCacheHome, home) {
    return (xdgCacheHome ? xdgCacheHome : home + "/.cache") + "/quickshell/art";
}

// A short hash of `text` (FNV-1a, 32 bits, in hex): names a fetched art's
// cache file after its URL.
function hash(text) {
    let value = 0x811c9dc5;
    for (let index = 0; index < text.length; index++) {
        value ^= text.charCodeAt(index);
        value = Math.imul(value, 0x01000193) >>> 0;
    }
    return ("0000000" + value.toString(16)).slice(-8);
}

// What Quickshell's ColorQuantizer reads a track's art (`url`) from, which
// only reads local files: { source, fetch }. Local art (a file:// URL or a
// path) is read as it is, with nothing to fetch. Art on the web (http or
// https, Spotify's) is read from its copy in `cacheDir`, named by a hash of
// the URL, and `fetch` is { url, path }: what to download there first, unless
// that file is already there. No art is nothing to read.
function artSource(url, cacheDir) {
    const text = url ? String(url) : "";
    if (!/^https?:\/\//.test(text))
        return { source: text, fetch: null };
    const path = cacheDir + "/" + hash(text);
    return { source: "file://" + path, fetch: { url: text, path: path } };
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
