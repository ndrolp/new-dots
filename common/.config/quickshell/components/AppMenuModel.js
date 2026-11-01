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

// Every menu for the focused window, in order. `context` is { app }, `app`
// null when no window is focused. Later menus (Window, Desktop, the app's
// own global menu) are added to this list.
function menus(context) {
    return context.app ? [appNameMenu(context.app)] : [];
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
