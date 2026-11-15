.pragma library

// The printers CUPS has added, read from `lpstat`, their print jobs, read
// over IPP with `ipptool`, and the commands that change them. Pure, no Quickshell; Printers.qml runs the commands.

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

// Is `host` this computer (localhost, 127.x or ::1, with or without brackets)?
function isLoopback(host) {
    const name = String(host).toLowerCase().replace(/^\[|\]$/g, "");
    return name === "localhost" || name === "::1" || name.startsWith("127.");
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
    if ((scheme === "ipp" || scheme === "ipps") && isLoopback(host))
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

// A print job's state from its IPP job-state: "waiting", "held",
// "printing" or "stopped". Get-Jobs only returns jobs not completed.
var jobStates = {
    "pending": "waiting",
    "pending-held": "held",
    "processing": "printing",
    "processing-stopped": "stopped"
};

// The fields of one line of `ipptool -c` CSV. A field with a comma or a
// quote is quoted, with a backslash before a quote or backslash inside.
function csvFields(line) {
    const fields = [];
    let field = "";
    let quoted = false;
    for (let i = 0; i < line.length; i++) {
        const c = line[i];
        if (quoted && c === "\\" && i + 1 < line.length)
            field += line[++i];
        else if (c === "\"")
            quoted = !quoted;
        else if (c === "," && !quoted) {
            fields.push(field);
            field = "";
        } else
            field += c;
    }
    fields.push(field);
    return fields;
}

// How far a print job is: "Page 2 of 5", "Page 2", or "" when unknown.
function progressOf(done, total) {
    if (!(done > 0))
        return "";
    return total > 0 ? "Page " + done + " of " + total : "Page " + done;
}

// Every print job in `text`, what `ipptool -c` prints for get-jobs.test:
// [{ id, document, owner, state, progress }], in the order CUPS gives.
function parseJobs(text) {
    const lines = String(text || "").split("\n").filter(line => line.trim() !== "");
    if (lines.length === 0)
        return [];
    const header = csvFields(lines[0]);
    const jobs = [];
    for (const line of lines.slice(1)) {
        const fields = csvFields(line);
        const value = name => fields[header.indexOf(name)] || "";
        const id = parseInt(value("job-id"), 10);
        if (!(id > 0))
            continue;
        jobs.push({
            id: id,
            document: value("job-name"),
            owner: value("job-originating-user-name"),
            state: jobStates[value("job-state")] || "waiting",
            progress: progressOf(parseInt(value("job-impressions-completed"), 10),
                parseInt(value("job-impressions"), 10))
        });
    }
    return jobs;
}

// Reads a printer's print jobs not completed, for parseJobs(). lpstat
// doesn't tell the document name, so this asks CUPS over IPP.
function jobsCommand(name) {
    return ["env", "LC_ALL=C", "ipptool", "-c", "ipp://localhost/printers/" + encodeURIComponent(name),
        "/usr/share/cups/ipptool/get-jobs.test"];
}

function cancelJobCommand(id) {
    return ["cancel", String(id)];
}

// CUPS's own test page, from cups-filters (a dependency of cups).
function testPageCommand(name) {
    return ["lp", "-d", name, "-t", "Test page", "/usr/share/cups/data/default-testpage.pdf"];
}
