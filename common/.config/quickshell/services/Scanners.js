.pragma library

// The scanners SANE can see, read from `scanimage`, and how a scan is
// named and run. Pure, no Quickshell; Scanners.qml runs the commands.

// Lists every device, one per line: name, vendor, model and type, split by
// tabs (none of them holds one).
var listCommand = ["scanimage", "-f", "%d\t%v\t%m\t%t%n"];

// Succeeds when SANE loads sane-airscan, without which no network scanner
// shows up (its package drops a file in dll.d; dll.conf may list it too).
var airscanCheckCommand = ["sh", "-c",
    "test -e /etc/sane.d/dll.d/airscan || grep -qsx '[[:space:]]*airscan[[:space:]]*' /etc/sane.d/dll.conf"];

// What the panel says when sane-airscan is missing.
var airscanMissing = "sane-airscan isn't installed, so network scanners can't be found. "
    + "Install sane-airscan to see them.";

// The notification after a scan saved to `path`, with *Open* and *Show in
// folder*. notify-send waits for the choice and prints its name; the file
// manager is asked to show the file, or the folder opens.
function savedNoticeCommand(path) {
    return ["sh", "-c",
        'action=$(notify-send -a Scanner -i document-scan -A open=Open -A folder="Show in folder" '
        + '"Scan saved" "$1")\n'
        + 'case "$action" in\n'
        + '  open) xdg-open "$1" ;;\n'
        + '  folder) gdbus call --session --dest org.freedesktop.FileManager1 '
        + '--object-path /org/freedesktop/FileManager1 --method org.freedesktop.FileManager1.ShowItems '
        + '"[\'file://$1\']" "" >/dev/null 2>&1 || xdg-open "${1%/*}" ;;\n'
        + 'esac',
        "sh", path];
}

// How a scanner with the SANE device name `device` is connected: "network"
// (sane-airscan, the escl and net backends, or a backend's own "net"
// address such as epson2:net:… or hpaio:/net/…) or "usb".
function connectionOf(device) {
    const backend = String(device).split(":")[0].toLowerCase();
    if (backend === "airscan" || backend === "escl" || backend === "net")
        return "network";
    return /[:/]net[:/]/i.test(device) ? "network" : "usb";
}

// Every scanner in `text`, what listCommand prints: [{ device, name,
// connection }], in the order SANE lists them. Webcams (the v4l backend)
// aren't scanners and are left out.
function parse(text) {
    const scanners = [];
    for (const line of String(text || "").split("\n")) {
        const fields = line.split("\t");
        const device = fields[0].trim();
        if (device === "" || fields.length < 3 || /^v4l:/i.test(device))
            continue;
        const vendor = fields[1].trim();
        const model = fields[2].trim();
        const name = model.toLowerCase().startsWith(vendor.toLowerCase()) || vendor === "" ? model
            : vendor + " " + model;
        scanners.push({ device: device, name: name || device, connection: connectionOf(device) });
    }
    return scanners;
}

// Where scans go: ~/Pictures/Scans, created when a scan starts.
function folder(home) {
    return home + "/Pictures/Scans";
}

function pad(number) {
    return number < 10 ? "0" + number : String(number);
}

// A scan started at `date` (local time), as a `format` file:
// scan-YYYY-MM-DD-HHMMSS.<format>.
function fileName(date, format) {
    return "scan-" + date.getFullYear() + "-" + pad(date.getMonth() + 1) + "-" + pad(date.getDate())
        + "-" + pad(date.getHours()) + pad(date.getMinutes()) + pad(date.getSeconds()) + "." + format;
}

function filePath(home, date, format) {
    return folder(home) + "/" + fileName(date, format);
}

// The choices in the scan view, as { label, value }.
var resolutions = [{ label: "150 dpi", value: 150 }, { label: "300 dpi", value: 300 },
    { label: "600 dpi", value: 600 }];
var modes = [{ label: "Colour", value: "color" }, { label: "Greyscale", value: "gray" },
    { label: "Black and white", value: "lineart" }];
var formats = [{ label: "PDF", value: "pdf" }, { label: "PNG", value: "png" }];

var defaultSettings = { resolution: 300, mode: "color", format: "pdf" };

// SANE's names for the colour modes.
var saneModes = { color: "Color", gray: "Gray", lineart: "Lineart" };

function choice(options, value, fallback) {
    return options.some(option => option.value === value) ? value : fallback;
}

// The scan settings `stored` in appearance.json ({ resolution, mode,
// format }), with the default for any that is missing or isn't a choice.
function settings(stored) {
    const given = stored || {};
    return {
        resolution: choice(resolutions, given.resolution, defaultSettings.resolution),
        mode: choice(modes, given.mode, defaultSettings.mode),
        format: choice(formats, given.format, defaultSettings.format)
    };
}

// Scans one page from `device` with `scanSettings` into `path`, making its
// folder first. `-p` prints progress on stderr (see progressOf); a failed
// scan leaves no half-written file behind.
function scanCommand(device, scanSettings, path) {
    const chosen = settings(scanSettings);
    const folderOf = path.slice(0, path.lastIndexOf("/")) || "/";
    return ["sh", "-c",
        'mkdir -p -- "$1" && out=$2 && shift 2 && "$@" || { status=$?; rm -f -- "$out"; exit "$status"; }',
        "sh", folderOf, path,
        "scanimage", "-d", device, "--resolution", String(chosen.resolution),
        "--mode", saneModes[chosen.mode], "--format=" + chosen.format, "-p", "-o", path];
}

// How far a scan is, 0 to 1, from what scanCommand has printed on stderr so
// far: scanimage rewrites "Progress: N%" with carriage returns.
function progressOf(stderr) {
    const matches = String(stderr || "").match(/Progress: ([0-9.]+)%/g);
    if (!matches)
        return 0;
    const percent = parseFloat(matches[matches.length - 1].slice("Progress: ".length));
    return Math.max(0, Math.min(1, percent / 100));
}

// Why a scan failed, from what scanCommand printed on stderr.
function failureOf(stderr) {
    const lines = String(stderr || "").split(/[\r\n]/)
        .map(line => line.replace(/^scanimage:\s*/, "").replace(/^sane_\w+:\s*/, "").trim())
        .filter(line => line !== "" && !line.startsWith("Progress:"));
    return lines.length > 0 ? lines[lines.length - 1] : "The scan failed";
}
