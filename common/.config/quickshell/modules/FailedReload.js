.pragma library

// The failed reload notice: when Quickshell's live reload fails, the shell
// that keeps running raises a critical notification naming the first error
// line; the next successful reload withdraws it. FailedReload.qml runs the
// commands and keeps the shown notice's id across reloads.

const summary = "Shell reload failed";
const explanation = "Quickshell couldn't load its config and is still running the previous one.";

// The first line of `errorString` with text in it, or a fallback.
function firstErrorLine(errorString) {
    const lines = String(errorString || "").split("\n")
        .map(line => line.trim())
        .filter(line => line !== "");
    return lines.length > 0 ? lines[0] : "No error details.";
}

// The notification server reads the body as markup.
function escaped(text) {
    return text.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
}

// The command that shows the notice for a failed reload, replacing the one
// already shown (`shownId`, 0 for none) instead of stacking another. It
// prints the notice's id (see shownId).
function failedCommand(errorString, shownId) {
    const replace = shownId > 0 ? ["-r", String(shownId)] : [];
    return ["notify-send", "-a", "Quickshell", "-u", "critical", "-i", "dialog-error", "-p"]
        .concat(replace)
        .concat([summary, explanation + "\n" + escaped(firstErrorLine(errorString))]);
}

// The id of the notice shown, from what failedCommand prints; 0 if none.
function shownId(output) {
    const id = parseInt(String(output || "").trim(), 10);
    return id > 0 ? id : 0;
}

// The command that withdraws the shown notice after a successful reload, or
// null when none is shown.
function completedCommand(shownId) {
    if (!(shownId > 0))
        return null;
    return ["gdbus", "call", "--session",
        "--dest", "org.freedesktop.Notifications",
        "--object-path", "/org/freedesktop/Notifications",
        "--method", "org.freedesktop.Notifications.CloseNotification", String(shownId)];
}
