.pragma library
.import "RecordingIndicator.js" as RecordingIndicator

// The privacy indicator bar element: pure logic, no Quickshell. Which apps
// use the microphone or a camera, read from the PipeWire graph the way the
// recording indicator reads screen shares; sharing the screen stays the
// recording indicator's (RecordingIndicator.screenShares).

// The device kinds an app can capture from, in the order they are shown.
const kinds = Object.freeze(["microphone", "camera"]);

// The apps capturing from each device kind, { microphone: [apps], camera:
// [apps] }, each app named once per kind, in the order their links come.
// An app uses a device while one of its recording streams is linked to it.
// `nodes` are `{ id, isStream, properties }` and `links` are
// `{ source, target }` node ids.
function captures(nodes, links) {
    const byId = {};
    nodes.forEach(node => byId[node.id] = node);

    const used = { microphone: [], camera: [] };
    links.forEach(link => {
        const source = byId[link.source];
        const target = byId[link.target];
        const kind = source && target && isRecording(target) ? deviceKind(source) : "";
        if (kind !== "")
            addOnce(used[kind], appName(target));
    });
    return used;
}

// The kind of device `node` is, "microphone" or "camera", or "" for any
// other node. A microphone is an audio source: a device, or the virtual one
// of a noise filter an app records from. A camera is a video source that
// isn't a screen the portal shares.
function deviceKind(node) {
    if (node.isStream)
        return "";

    const mediaClass = String((node.properties || {})["media.class"] || "");
    if (mediaClass.startsWith("Audio/Source"))
        return "microphone";
    if (mediaClass === "Video/Source" && !RecordingIndicator.isSharedScreen(node))
        return "camera";
    return "";
}

// The binaries the shell itself runs as.
const shellBinaries = ["quickshell", "qs"];

// An app's stream that records, not one that only listens for levels: cava
// captures the output (stream.capture.sink), a level meter only monitors
// (stream.monitor), and nothing the shell itself reads counts. Nor does the
// capture half of a loopback or filter chain (a noise filter's), which
// PipeWire marks with node.link-group: the app recording from the filter is
// what counts.
function isRecording(node) {
    const properties = node.properties || {};
    return node.isStream === true
        && !isSet(properties["stream.capture.sink"])
        && !isSet(properties["stream.monitor"])
        && !properties["node.link-group"]
        && shellBinaries.indexOf(properties["application.process.binary"]) === -1;
}

// Whether a PipeWire flag is on: PipeWire gives its properties as strings
// ("true"), pw-dump as booleans.
function isSet(flag) {
    return flag === true || flag === "true";
}

// An app's name: its own, else its binary's, else its stream's.
function appName(node) {
    const properties = node.properties || {};
    return properties["application.name"] || properties["application.process.binary"]
        || properties["node.name"] || "";
}

// How each device kind is shown: its icon on the bar and its title in the
// popup.
const kindIcons = Object.freeze({ microphone: "󰍬", camera: "󰕧" });
const kindTitles = Object.freeze({ microphone: "Microphone", camera: "Camera" });

// The kinds `captures` (see captures) has an app using.
function kindsInUse(captures) {
    return kinds.filter(kind => ((captures || {})[kind] || []).length > 0);
}

// Whether any app uses the microphone or a camera: when the element shows.
function capturing(captures) {
    return kindsInUse(captures).length > 0;
}

// The icons the element shows: the mic's, the camera's or both.
function icons(captures) {
    return kindsInUse(captures).map(kind => kindIcons[kind]);
}

// What the popup lists: per device kind in use, [{ kind, title, icon,
// apps }], an app with no name at all listed as "An app".
function sections(captures) {
    return kindsInUse(captures).map(kind => ({
        kind: kind,
        title: kindTitles[kind],
        icon: kindIcons[kind],
        apps: captures[kind].map(app => app !== "" ? app : "An app")
    }));
}

function addOnce(list, value) {
    if (list.indexOf(value) === -1)
        list.push(value);
}
