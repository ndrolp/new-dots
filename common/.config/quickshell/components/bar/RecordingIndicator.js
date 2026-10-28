.pragma library
.import "../StatusText.js" as StatusText

// The recording indicator bar element: pure logic, no Quickshell.
// What is recording is a list of recordings, each started at `startedAt` (ms
// since the epoch), of one of the `kinds` below.

// What a recording is: the shell's own wf-recorder, or a screen another app
// shares through PipeWire (with the sharing `app`).
const kinds = Object.freeze({ own: "own", share: "share" });

// The recordings under way. `ownStartedAt` is when the shell's own recording
// started, or 0 while it isn't recording; `shares` are the screen shares with
// their start times (see startTimes).
function recordings(ownStartedAt, shares) {
    const own = ownStartedAt > 0 ? [{ kind: kinds.own, startedAt: ownStartedAt }] : [];
    return own.concat((shares || []).map(share =>
        ({ kind: kinds.share, app: share.app, startedAt: share.startedAt })));
}

// The indicator shows only while something records.
function shown(recordings) {
    return recordings.length > 0;
}

// The screens other apps are sharing through PipeWire, as `{ id, app }`: one
// per screen the portal offers, named after the app reading it (empty until
// one is linked). `nodes` are `{ id, isStream, properties }` and `links` are
// `{ source, target }` node ids.
function screenShares(nodes, links) {
    const byId = {};
    nodes.forEach(node => byId[node.id] = node);

    return nodes.filter(isSharedScreen).map(screen => {
        const link = links.find(link => link.source === screen.id && byId[link.target]);
        return { id: screen.id, app: link ? appName(byId[link.target]) : "" };
    });
}

// A screen the portal offers is a video source with no device behind it;
// cameras are devices, and virtual cameras (OBS's, a v4l2loopback node, any
// node whose name or description says camera) aren't screens either.
function isSharedScreen(node) {
    const properties = node.properties || {};
    return !node.isStream
        && properties["media.class"] === "Video/Source"
        && properties["media.role"] !== "Camera"
        && !properties["device.api"]
        && !isVirtualCamera(properties);
}

const cameraWords = /camera|webcam|\bcam\b|v4l2loopback|v4l2 loopback/i;

function isVirtualCamera(properties) {
    return ["node.name", "node.nick", "node.description", "media.name",
        "device.description", "api.v4l2.cap.driver", "api.v4l2.cap.card"]
        .some(key => cameraWords.test(String(properties[key] || "")));
}

function appName(node) {
    const properties = node.properties || {};
    return properties["application.name"] || properties["application.process.binary"] || "";
}

// The screen shares with when each was first seen: a share already in
// `previous` keeps its start time, a new one starts at `now`.
function startTimes(previous, shares, now) {
    return shares.map(share => {
        const known = previous.find(started => started.id === share.id);
        return { id: share.id, app: share.app, startedAt: known ? known.startedAt : now };
    });
}

// Which apps are sharing the screen, each named once, for a click while
// nothing of the shell's own can be stopped.
function sharingText(recordings) {
    const apps = [];
    recordings.forEach(recording => {
        if (recording.kind === kinds.share && recording.app !== "" && !apps.includes(recording.app))
            apps.push(recording.app);
    });
    return apps.length > 0 ? apps.join(", ") : "An app";
}

// Clicking stops a recording only when it is the shell's own.
function stoppable(recordings) {
    return recordings.some(recording => recording.kind === kinds.own);
}

// The time since the earliest recording started, at `now` (ms since the
// epoch); empty while nothing records.
function elapsedSince(recordings, now) {
    if (recordings.length === 0)
        return "";

    const startedAt = Math.min(...recordings.map(recording => recording.startedAt));
    return StatusText.duration((now - startedAt) / 1000);
}
