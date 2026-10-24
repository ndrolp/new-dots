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

// How long to wait, in ms, before starting cava again after it failed
// `failures` times in a row: a few seconds, doubling up to a minute, so a
// cava that keeps failing isn't restarted in a tight loop.
function retryDelay(failures) {
    return Math.min(60000, 3000 * Math.pow(2, Math.max(0, failures - 1)));
}

// The hint the Bar section shows under Cava when cava exited on its own with
// `exitCode`. The shell runs cava through sh, which exits 127 when it can't
// find cava.
function failureHint(exitCode) {
    if (exitCode === 127)
        return "cava isn't installed, so the bars stay flat.";
    return "cava failed to start, so the bars stay flat. Trying again in a few seconds.";
}
