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

// The Hyprland dispatch moving a window to a workspace without following it,
// wherever the window or the workspace are. Null for anything but an address.
function moveDispatch(address, workspace) {
    const window = windowSelector(address);

    if (window === null)
        return null;

    return "hl.dsp.window.move({ workspace = " + workspace
        + ", follow = false, window = \"" + window + "\" })";
}

// The `hyprctl --batch` moving a window to a workspace that doesn't exist yet and
// leaving that workspace on `monitor`, without following it. Hyprland only makes
// a workspace for the window, on the focused monitor or the one a rule names,
// and one with nothing in it can't be sent anywhere, so it takes both steps. The
// new workspace isn't active, so sending it on changes no focus. Null for
// anything but an address and a monitor's name.
function newWorkspaceBatch(address, workspace, monitor) {
    const move = moveDispatch(address, workspace);

    if (move === null || !/^[\w.-]+$/.test(monitor))
        return null;

    return "dispatch " + move + " ; dispatch hl.dsp.workspace.move({ workspace = "
        + workspace + ", monitor = \"" + monitor + "\" })";
}
