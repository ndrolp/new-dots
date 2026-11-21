.pragma library

// What WorkspaceService.qml decides, without Quickshell: which workspaces the
// shell lists, which windows one shows, and the commands that move and focus.

const firstWorkspace = 1;
const lastWorkspace = 21;

function isListed(id) {
    return id >= firstWorkspace && id <= lastWorkspace;
}

// Whether a window appears on a workspace's miniature. `window` is what Hyprland
// reports for it, so nothing until it's been described; `focused` is the
// workspace you're on. A scratchpad window's workspace has a negative id, which
// is never one listed. Of a window group, only the active window isn't hidden.
function isShownOn(window, workspace, focused) {
    return window.workspace?.id === workspace
        && !window.hidden
        && (!window.pinned || workspace === focused);
}

// Hyprland's fullscreen mode is a bit set: 1 maximized, 2 fullscreen.
const fullscreenMode = 2;

// Whether a workspace has a real fullscreen window, not just a maximized one.
// `windows` are what Hyprland reports for them, as isShownOn takes them.
function hasFullscreen(windows, workspace) {
    return (windows || []).some(window => window.workspace?.id === workspace
        && ((window.fullscreen || 0) & fullscreenMode) !== 0);
}

// How Hyprland is told which window, or null for anything but an address.
function windowSelector(address) {
    if (!/^(?:0x)?[0-9a-f]+$/i.test(address))
        return null;

    return "address:" + (address.startsWith("0x") ? address : "0x" + address);
}

// Where scrolling over a monitor's workspaces goes: the workspace after
// `current` in `shown` for a step of 1, the one before it for -1. `shown` is
// what the monitor shows, in ascending order; from a workspace it doesn't
// show, the nearest shown one that way. Null past either end.
function scrollTarget(shown, current, step) {
    const index = shown.indexOf(current);
    if (index !== -1) {
        const target = index + step;
        return target >= 0 && target < shown.length ? shown[target] : null;
    }

    const ahead = shown.filter(id => step > 0 ? id > current : id < current);
    return ahead.length === 0 ? null : step > 0 ? ahead[0] : ahead[ahead.length - 1];
}

function focusWorkspaceDispatch(workspace) {
    return "hl.dsp.focus({ workspace = " + workspace + " })";
}

// The Hyprland dispatch focusing a window, or null for anything but an address.
function focusWindowDispatch(address) {
    const window = windowSelector(address);

    return window === null ? null : "hl.dsp.focus({ window = \"" + window + "\" })";
}

// A dispatch that brings a workspace into being, then that workspace sent to
// `monitor`. Hyprland makes a workspace on the focused monitor or the one a rule
// names, and one with nothing in it can't be sent anywhere, so it takes both
// steps; sending it to the monitor it's on already does nothing. Null for
// anything but a monitor's name.
function settledOn(dispatch, workspace, monitor) {
    if (!/^[\w.-]+$/.test(monitor))
        return null;

    return ["hyprctl", "--batch", "dispatch " + dispatch
        + " ; dispatch hl.dsp.workspace.move({ workspace = " + workspace
        + ", monitor = \"" + monitor + "\" })"];
}

// The command moving a window to a workspace without following it, wherever
// the window or the workspace are. A workspace that doesn't `exist` yet ends up
// on `monitor`; it isn't active, so sending it there changes no focus. Null for
// anything but an address and a monitor's name.
function moveCommand(address, workspace, monitor, exists) {
    const window = windowSelector(address);

    if (window === null)
        return null;

    const move = "hl.dsp.window.move({ workspace = " + workspace
        + ", follow = false, window = \"" + window + "\" })";

    return exists ? ["hyprctl", "dispatch", move] : settledOn(move, workspace, monitor);
}

// The command making a new workspace on `monitor` and going to it.
function createCommand(workspace, monitor) {
    return settledOn(focusWorkspaceDispatch(workspace), workspace, monitor);
}
