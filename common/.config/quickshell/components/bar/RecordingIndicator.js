.pragma library

// The recording indicator bar element: pure logic, no Quickshell.
// What is recording is a list of recordings. Today the only kind is the
// shell's own wf-recorder ("own"), started at `startedAt` (ms since the
// epoch).

// The recordings under way. `ownStartedAt` is when the shell's own recording
// started, or 0 while it isn't recording.
function recordings(ownStartedAt) {
    return ownStartedAt > 0 ? [{ kind: "own", startedAt: ownStartedAt }] : [];
}

// The indicator shows only while something records.
function shown(recordings) {
    return recordings.length > 0;
}

// Clicking stops a recording only when it is the shell's own.
function stoppable(recordings) {
    return recordings.some(recording => recording.kind === "own");
}

// The time since the earliest recording started, at `now` (ms since the
// epoch); empty while nothing records.
function elapsedSince(recordings, now) {
    if (recordings.length === 0)
        return "";

    const startedAt = Math.min(...recordings.map(recording => recording.startedAt));
    return elapsedText((now - startedAt) / 1000);
}

// The time since a recording started, as m:ss or h:mm:ss. Part seconds are
// dropped.
function elapsedText(seconds) {
    const total = Math.max(0, Math.floor(seconds));
    const hours = Math.floor(total / 3600);
    const minutes = Math.floor(total / 60) % 60;
    const twoDigits = value => String(value).padStart(2, "0");
    const rest = twoDigits(total % 60);

    return hours > 0
        ? hours + ":" + twoDigits(minutes) + ":" + rest
        : minutes + ":" + rest;
}
