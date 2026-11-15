.pragma library

// What the Printers panel's sections say of a printer, a print job and how
// a printer or scanner is connected.

var connectionLabels = { network: "Network", usb: "USB", local: "Local" };
var statusLabels = { idle: "Idle", printing: "Printing", stopped: "Stopped", error: "Error" };
var jobLabels = { waiting: "Waiting", held: "Held", printing: "Printing", stopped: "Stopped" };

function connectionText(connection) {
    return connectionLabels[connection] || "Network";
}

// A printer's state, with the reason when there is one.
function statusText(printer) {
    const label = statusLabels[printer.state] || "Unknown";
    return printer.reason ? label + ": " + printer.reason : label;
}

// What the panel says under a print job's document name.
function jobText(job) {
    return [jobLabels[job.state] || "Waiting", job.progress, job.owner].filter(part => part).join(" · ");
}
