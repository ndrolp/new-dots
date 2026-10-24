.pragma library

// How the shell talks to cava: the config it runs cava with and the frames
// cava prints back, as bar heights. Pure, no Quickshell.

// cava prints each bar as a whole number up to this.
const maxRange = 1000;

// cava's config for `barCount` bars: it listens to the monitor of the default
// audio output (pipewire's "auto" source) and prints one frame per line,
// bars separated by ";" (59), as text. One set of mono frequency bars: in
// stereo cava mirrors the two channels.
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

// Whether a frame is silence: every bar flat.
function frameSilent(heights) {
    return (heights || []).every(height => height === 0);
}

// How long, in ms, a run of silent frames lasts before the Cava bar element
// hides, so it doesn't flicker out in the quiet between two songs.
const silenceDelay = 2000;

// How long to wait, in ms, before starting cava again after it failed
// `failures` times in a row: a few seconds, doubling up to a minute, so a
// cava that keeps failing isn't restarted in a tight loop.
function retryDelay(failures) {
    return Math.min(60000, 3000 * Math.pow(2, Math.max(0, failures - 1)));
}

// The hint the Bar section shows under Cava when cava exited on its own with
// `exitCode`, after printing a frame or not (`printedFrame`), to be tried
// again in `retryDelay` ms. The shell runs cava through sh, which exits 127
// when it can't find cava.
function failureHint(exitCode, printedFrame, retryDelay) {
    if (exitCode === 127)
        return "cava isn't installed, so the bars stay flat.";
    const wait = " Trying again in " + Math.round(retryDelay / 1000) + " seconds.";
    if (printedFrame)
        return "cava stopped unexpectedly, so the bars stay flat." + wait;
    return "cava failed to start, so the bars stay flat." + wait;
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

// When the one shared cava runs: plain state, changed only through the
// functions below, which return the next state. Cava.qml starts or stops cava
// to match `running` and, while `retrying`, calls retryDue after
// `retryDelay` ms.
// - drawn: some bar draws the Cava bar element.
// - restarting: cava was stopped on purpose, to start again once it exits.
// - failures: exits nobody asked for in a row, since cava last printed a frame.
// - printedFrame: cava printed a frame since it last started.
// - failureHint: what the Bar section says under Cava ("" while cava runs).
const stopped = {
    drawn: false, running: false, restarting: false, retrying: false, retryDelay: 0,
    failures: 0, printedFrame: false, failureHint: ""
};

// Some bar started (`drawn`) or stopped drawing Cava: cava runs only while
// one does. Once none does, nothing is retried and there is no hint.
function drawnChanged(state, drawn) {
    if (!drawn)
        return Object.assign({}, stopped, { restarting: state.restarting });
    return Object.assign({}, state, { drawn: true, running: true, retrying: false });
}

// cava printed a frame: it runs, so the failures and the hint are over.
function framePrinted(state) {
    return Object.assign({}, state, { printedFrame: true, failures: 0, failureHint: "" });
}

// The wait after a failure is over: cava starts again if a bar still draws it.
function retryDue(state) {
    return Object.assign({}, state, { retrying: false, running: state.drawn });
}

// A planned restart, so cava follows a new default output or bar count: it
// stops, and starts again once it exited (see exited).
function restartAsked(state) {
    if (!state.running)
        return state;
    return Object.assign({}, state, { running: false, restarting: true });
}

// cava exited with `exitCode`. After a planned restart it starts again; an
// exit nobody asked for while a bar draws Cava is a failure: a hint and a
// retry a while later, longer the more it fails.
function exited(state, exitCode) {
    const next = Object.assign({}, state, { running: false, printedFrame: false });

    if (state.restarting)
        return Object.assign(next, { restarting: false, running: state.drawn });
    if (!state.drawn)
        return next;

    const failures = state.failures + 1;
    const delay = retryDelay(failures);
    return Object.assign(next, {
        failures: failures, retrying: true, retryDelay: delay,
        failureHint: failureHint(exitCode, state.printedFrame, delay)
    });
}
