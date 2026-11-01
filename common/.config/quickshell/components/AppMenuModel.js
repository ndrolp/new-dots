.pragma library

// The app menu's model: the menus for the focused window, described as plain
// data. Pure, no Quickshell. The app menu's Popup draws from it, and so can
// anything else that shows these menus (e.g. the app menu popover).
//
// An app is { appId, entry }, `entry` being its .desktop file as
// { name, actions: [{ id, name }] }, or null when it has none.
//
// A menu is { id, title, items }. An item is one of:
//   { kind: "action", label, action, enabled? }  runs `action` when chosen
//   { kind: "separator" }
//   { kind: "submenu", label, items }            opens `items`
// An action is data saying what to do, run by AppMenuActions.qml:
//   { kind: "desktopAction", appId, actionId }   a .desktop action
//   { kind: "newWindow", appId }                 runs the app again
//   { kind: "quit", appId }                      closes every window of the app
//   { kind: "window", operation, address, workspace? }
//                                                acts on one window, see windowCommand
//   { kind: "openPanel", panel }                 opens a shell panel
//                                                (see openPanelCommand)

const separator = Object.freeze({ kind: "separator" });

function action(label, what) {
    return { kind: "action", label: label, action: what };
}

function appName(app) {
    return app.entry && app.entry.name ? app.entry.name : app.appId;
}

// The app-name menu: the app's .desktop actions, then New Window and
// Quit <App>. A .desktop action called "New Window" is left out, since the
// shell's own does the same.
function appNameMenu(app) {
    const name = appName(app);
    const desktopActions = (app.entry && app.entry.actions || [])
        .filter(desktopAction => desktopAction.name !== "New Window")
        .map(desktopAction => action(desktopAction.name,
            { kind: "desktopAction", appId: app.appId, actionId: desktopAction.id }));
    const items = desktopActions.length > 0 ? desktopActions.concat([separator]) : [];

    return {
        id: "app",
        title: name,
        items: items.concat([
            action("New Window", { kind: "newWindow", appId: app.appId }),
            separator,
            action("Quit " + name, { kind: "quit", appId: app.appId })
        ])
    };
}

// The Desktop menu, shown in place of an app when no window is focused:
// the unified search, the settings panel and the wallpaper selector.
function desktopMenu() {
    return {
        id: "desktop",
        title: "Desktop",
        items: [
            action("Open Launcher", { kind: "openPanel", panel: "unifiedSearch" }),
            action("Settings Panel", { kind: "openPanel", panel: "settings" }),
            action("Change Wallpaper", { kind: "openPanel", panel: "wallpaperSelector" })
        ]
    };
}

// The IPC target of each panel an openPanel action names.
const panelIpcTargets = Object.freeze({
    unifiedSearch: "unified-search",
    settings: "config",
    wallpaperSelector: "wallpapers"
});

// openPanel: the command that opens `panel` through its IPC handler, as the
// keybinds do, `shellDir` being this shell's config directory. [] for an
// unknown panel.
function openPanelCommand(panel, shellDir) {
    const target = panelIpcTargets[panel];
    return target ? ["quickshell", "ipc", "--path", shellDir, "call", target, "show"] : [];
}

// Every menu for the focused window, in order. `context` is { app, window },
// `app` null when no window is focused, which gives the Desktop menu instead,
// `window` the focused window as windowMenu takes it (or null, leaving the
// Window menu out). Later menus (the app's own global menu) join this list.
function menus(context) {
    if (!context.app)
        return [desktopMenu()];
    const list = [appNameMenu(context.app)];
    if (context.window)
        list.push(windowMenu(context.window));
    return list;
}

// The focused window, as CurrentApp follows it: Hyprland's active window
// while it is on the focused workspace, or null.
function focusedWindow(activeToplevel, focusedWorkspace) {
    return activeToplevel && activeToplevel.workspace && focusedWorkspace
        && activeToplevel.workspace.id === focusedWorkspace.id ? activeToplevel : null;
}

function windowAddress(address) {
    if (!/^(?:0x)?[0-9a-f]+$/i.test(address || ""))
        return "";
    return address.startsWith("0x") ? address : "0x" + address;
}

// Quit: the hyprctl commands that politely close every window of `appId`,
// `windows` being [{ appId, address }]. Apps with unsaved work ask on their
// own.
function quitCommands(appId, windows) {
    return windows
        .filter(window => window.appId === appId && windowAddress(window.address) !== "")
        .map(window => ["hyprctl", "dispatch",
            "hl.dsp.window.close({ window = \"address:" + windowAddress(window.address) + "\" })"]);
}

// The Window menu: Float/Tile, Fullscreen, Pin, Move to Workspace 1-10 and
// Close Window, each acting on `window`, which is the focused window as
// { address, floating, fullscreen, pinned }. The labels say what choosing
// them does to it now.
function windowMenu(window) {
    function windowAction(label, operation, extra) {
        return action(label, Object.assign({ kind: "window", operation: operation, address: window.address }, extra));
    }

    const workspaces = [];
    for (let workspace = 1; workspace <= 10; workspace++)
        workspaces.push(windowAction("Workspace " + workspace, "moveToWorkspace", { workspace: workspace }));

    return {
        id: "window",
        title: "Window",
        items: [
            windowAction(window.floating ? "Tile" : "Float", "toggleFloating"),
            windowAction(window.fullscreen ? "Exit Fullscreen" : "Fullscreen", "toggleFullscreen"),
            windowAction(window.pinned ? "Unpin" : "Pin", "togglePin"),
            separator,
            { kind: "submenu", label: "Move to Workspace", items: workspaces },
            separator,
            windowAction("Close Window", "close")
        ]
    };
}

// The hyprctl command for a Window menu action, or null when it can't be
// run safely (no usable address, a workspace that isn't a number).
function windowCommand(windowAction) {
    const address = windowAddress(windowAction.address);
    if (address === "")
        return null;
    const target = "window = \"address:" + address + "\"";
    let dispatch;
    if (windowAction.operation === "toggleFloating")
        dispatch = "hl.dsp.window.float({ action = \"toggle\", " + target + " })";
    else if (windowAction.operation === "toggleFullscreen")
        dispatch = "hl.dsp.window.fullscreen({ action = \"toggle\", " + target + " })";
    else if (windowAction.operation === "togglePin")
        dispatch = "hl.dsp.window.pin({ " + target + " })";
    else if (windowAction.operation === "close")
        dispatch = "hl.dsp.window.close({ " + target + " })";
    else if (windowAction.operation === "moveToWorkspace" && Number.isInteger(windowAction.workspace))
        dispatch = "hl.dsp.window.move({ workspace = " + windowAction.workspace + ", " + target + " })";
    else
        return null;
    return ["hyprctl", "dispatch", dispatch];
}
