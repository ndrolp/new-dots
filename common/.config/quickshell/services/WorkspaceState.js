.pragma library

// What WorkspaceService.qml decides, without Quickshell: which workspaces the
// shell lists, which windows one shows, and the commands that move and focus.

const firstWorkspace = 1;
const lastWorkspace = 21;

function isListed(id) {
    return id >= firstWorkspace && id <= lastWorkspace;
}

// Whether a window appears on a workspace's tile. `window` is what Hyprland
// reports for it, so nothing until it's been described; `focused` is the
// workspace you're on. A scratchpad window's workspace has a negative id, which
// is never a tile's. Of a window group, only the active window isn't hidden.
function isShownOn(window, workspace, focused) {
    return window.workspace?.id === workspace
        && !window.hidden
        && (!window.pinned || workspace === focused);
}

// How Hyprland is told which window, or null for anything but an address.
function windowSelector(address) {
    if (!/^(?:0x)?[0-9a-f]+$/i.test(address))
        return null;

    return "address:" + (address.startsWith("0x") ? address : "0x" + address);
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
