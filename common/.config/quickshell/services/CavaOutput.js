.pragma library

// How the shell talks to cava: the config it runs cava with and the frames
// cava prints back, as bar heights. Pure, no Quickshell.

// cava prints each bar as a whole number up to this.
const maxRange = 1000;

// cava's config for `barCount` bars: it listens to the monitor of the default
// audio output (pipewire's "auto" source) and prints one frame per line,
// bars separated by ";" (59), as text. One mono spectrum: in stereo cava
// mirrors the two channels.
function config(barCount) {
    return [
        "[general]",
        "bars = " + barCount,
        "framerate = 60",
        "",
        "[input]",
        "method = pipewire",
        "source = auto",
        "",
        "[output]",
        "method = raw",
        "raw_target = /dev/stdout",
        "data_format = ascii",
        "ascii_max_range = " + maxRange,
        "bar_delimiter = 59",
        "frame_delimiter = 10",
        "channels = mono",
        ""
    ].join("\n");
}

// `barCount` flat bars: what the Cava bar element shows in silence or while
// cava isn't running.
function flatHeights(barCount) {
    const heights = [];
    for (let index = 0; index < barCount; index++)
        heights.push(0);
    return heights;
}

// The heights of `barCount` bars, from 0 to 1, in one frame (a line) cava
// printed. Bars the frame lacks or garbles are flat; extra ones are ignored.
function frameHeights(frame, barCount) {
    const values = String(frame || "").split(";");
    const heights = flatHeights(barCount);

    for (let index = 0; index < barCount && index < values.length; index++) {
        const value = parseInt(values[index], 10);
        if (!isNaN(value))
            heights[index] = Math.max(0, Math.min(1, value / maxRange));
    }

    return heights;
}

// How many bars cava computes while no Cava bar element is drawn.
const defaultBarCount = 12;

// How many bars the one shared cava computes for Cava bar elements asking for
// `barCounts`: the most any of them asks for, so each resamples down to its
// own.
function sharedBarCount(barCounts) {
    return barCounts.length > 0 ? Math.max.apply(null, barCounts) : defaultBarCount;
}

// `heights` resampled to `barCount` bars: each bar is the tallest of the
// group of bars it stands for, so peaks survive. Flat without heights.
function resample(heights, barCount) {
    const source = heights || [];
    const resampled = flatHeights(barCount);

    if (source.length === 0)
        return resampled;

    for (let index = 0; index < barCount; index++) {
        const start = Math.floor(index * source.length / barCount);
        const end = Math.max(start + 1, Math.floor((index + 1) * source.length / barCount));
        resampled[index] = Math.max.apply(null, source.slice(start, end));
    }

    return resampled;
}
