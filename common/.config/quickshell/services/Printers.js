.pragma library

// The printers CUPS has added, read from `lpstat`, and the commands that
// change them. Pure, no Quickshell; Printers.qml runs the commands.

// Reads every printer, its state, alerts, the default and device URIs, in
// the English parse() reads.
var listCommand = ["env", "LC_ALL=C", "lpstat", "-l", "-p", "-d", "-v"];

// What went wrong reading the printers, from what listCommand printed on
// stderr ("" when nothing did). lpstat complains when no printer is added,
// which isn't a problem.
function listProblem(stderr) {
    const lines = String(stderr || "").split("\n")
        .map(line => line.replace(/^lpstat:\s*/, "").trim())
        .filter(line => line !== "" && line !== "No destinations added.");
    return lines.length > 0 ? lines[0] : "";
}

// The user is in wheel, which CUPS on Arch takes as an admin group, so
// these run without a password.
function setDefaultCommand(name) {
    return ["lpadmin", "-d", name];
}

function removeCommand(name) {
    return ["lpadmin", "-x", name];
}

// A printer's state as the Printers panel says it, with the reason when
// there is one.
function statusText(printer) {
    const label = { idle: "Idle", printing: "Printing", stopped: "Stopped", error: "Error" }[printer.state]
        || "Unknown";
    return printer.reason ? label + ": " + printer.reason : label;
}

function connectionText(connection) {
    return { network: "Network", usb: "USB", local: "Local" }[connection] || "Network";
}

// How a printer with the device URI `uri` is connected: "usb", "network"
// or "local" (a PDF or file printer). ipp-usb serves a USB printer as IPP
// on localhost, so that is USB too.
function connectionOf(uri) {
    const match = /^([a-z0-9+.-]+):\/*(\[[^\]]*\]|[^/:?]*)/i.exec(uri);
    if (!match)
        return "network";
    const scheme = match[1].toLowerCase();
    const host = match[2].toLowerCase();
    if (scheme === "usb" || (scheme === "hp" && host === "usb"))
        return "usb";
    if (scheme === "file" || scheme === "cups-pdf")
        return "local";
    if ((scheme === "ipp" || scheme === "ipps")
            && (host === "localhost" || host === "[::1]" || host.startsWith("127.")))
        return "usb";
    return "network";
}

// What an IPP printer-state-reason means to a person: "media-jam-error"
// is "Media jam".
function reasonText(reason) {
    const words = String(reason).replace(/-(error|warning|report)$/, "").replace(/-/g, " ");
    return words.charAt(0).toUpperCase() + words.slice(1);
}

// Every printer in `text`, what `lpstat -l -p -d -v` prints under LC_ALL=C:
// [{ name, description, state, reason, connection, isDefault }], by name.
// `state` is "idle", "printing", "stopped" or "error" (CUPS keeps a printer
// with an error idle or printing; its alerts tell), and `reason` is CUPS's
// message about it, or the error alert's, or "".
function parse(text) {
    const printers = [];
    const byName = {};
    let current = null;
    // The line right after a printer's first one is CUPS's message, if any.
    let messageNext = false;
    let defaultName = "";

    for (const line of String(text || "").split("\n")) {
        const header = /^printer (\S+) (?:is )?(idle|holding new jobs|now printing|disabled)/.exec(line);
        if (header) {
            current = {
                name: header[1],
                description: "",
                state: header[2] === "now printing" ? "printing"
                    : header[2] === "disabled" ? "stopped" : "idle",
                reason: "",
                connection: "network",
                isDefault: false
            };
            printers.push(current);
            byName[current.name] = current;
            messageNext = true;
            continue;
        }
        const indented = /^\t(.*)$/.exec(line);
        if (indented && current) {
            const detail = indented[1].trim();
            if (detail.startsWith("Description:"))
                current.description = detail.slice("Description:".length).trim();
            else if (detail.startsWith("Alerts:"))
                takeAlerts(current, detail.slice("Alerts:".length).trim().split(/\s+/));
            else if (messageNext && detail !== "reason unknown")
                current.reason = detail;
            messageNext = false;
            continue;
        }
        current = null;
        messageNext = false;
        const defaultLine = /^system default destination: (\S+)/.exec(line);
        if (defaultLine)
            defaultName = defaultLine[1];
        const device = /^device for (\S+): (.*)$/.exec(line);
        if (device && byName[device[1]])
            byName[device[1]].connection = connectionOf(device[2].trim());
    }

    if (byName[defaultName])
        byName[defaultName].isDefault = true;
    for (const printer of printers) {
        if (printer.state !== "stopped" && printer.state !== "error")
            printer.reason = "";
    }
    return printers.sort((first, second) => first.name.localeCompare(second.name));
}

// A printer whose alerts hold an error is in error, unless it's stopped.
function takeAlerts(printer, reasons) {
    const error = reasons.find(reason => reason.endsWith("-error"));
    if (!error || printer.state === "stopped")
        return;
    printer.state = "error";
    if (printer.reason === "")
        printer.reason = reasonText(error);
}
