import Quickshell
import Quickshell.Hyprland
import QtQuick
import "AppMenuModel.js" as AppMenuModel

// The app menu's live side: the focused app and its .desktop file, the menus
// it exports (through `bridge`), the menus AppMenuModel builds for it, and
// running the actions those menus hand over. Anything showing the app menu
// (its bar element and Popup, the popover) keeps one; the menus themselves
// are AppMenuModel's.
QtObject {
    id: root

    // The shell's services/AppMenuBridge.qml; without one, only the shell's
    // menus show.
    property var bridge: null

    readonly property var focusedWindow: AppMenuModel.focusedWindow(Hyprland.activeToplevel,
        Hyprland.focusedWorkspace)
    readonly property string appId: focusedWindow ? windowAppId(focusedWindow) : ""
    // Looked up again when the .desktop files (re)load, which happens after
    // startup.
    readonly property var desktopEntry: {
        DesktopEntries.applications.values;
        return appId !== "" ? DesktopEntries.heuristicLookup(appId) : null;
    }
    // The focused app as AppMenuModel takes it, or null with no window focused.
    readonly property var app: appId === "" ? null : {
        appId: appId,
        entry: desktopEntry ? {
            name: desktopEntry.name,
            actions: desktopEntry.actions.map(action => ({ id: action.id, name: action.name }))
        } : null
    }
    readonly property string appName: app ? AppMenuModel.appName(app) : ""
    // The focused window as AppMenuModel's Window menu takes it.
    readonly property var window: {
        if (!focusedWindow)
            return null;
        const ipc = focusedWindow.lastIpcObject || {};
        return {
            address: focusedWindow.address,
            floating: ipc.floating === true,
            fullscreen: (ipc.fullscreen || 0) > 0,
            pinned: ipc.pinned === true
        };
    }
    // What the focused app exports over D-Bus (see AppMenuModel.exportedMenus).
    readonly property var exported: {
        const pid = focusedWindow && focusedWindow.lastIpcObject ? focusedWindow.lastIpcObject.pid : undefined;
        return bridge && pid !== undefined ? bridge.exportedFor(pid) : null;
    }
    readonly property var menus: AppMenuModel.menus({ app: app, window: window, exported: exported })

    // Hyprland's window state (floating, fullscreen, pinned) is only read on
    // a refresh, so one is asked for whenever it changes.
    property Connections windowStateEvents: Connections {
        target: Hyprland

        function onRawEvent(event) {
            if (["changefloatingmode", "fullscreen", "pin"].includes(event.name))
                Hyprland.refreshToplevels();
        }
    }

    function windowAppId(toplevel) {
        if (toplevel.wayland && toplevel.wayland.appId)
            return toplevel.wayland.appId;
        return toplevel.lastIpcObject && toplevel.lastIpcObject.class
            ? toplevel.lastIpcObject.class : "";
    }

    function entryFor(appId) {
        return appId === root.appId ? desktopEntry : DesktopEntries.heuristicLookup(appId);
    }

    // Runs an action from AppMenuModel's menus.
    function run(action) {
        if (action.kind === "desktopAction") {
            const entry = entryFor(action.appId);
            const desktopAction = entry
                ? entry.actions.find(candidate => candidate.id === action.actionId) : null;
            if (desktopAction)
                desktopAction.execute();
        } else if (action.kind === "newWindow") {
            const entry = entryFor(action.appId);
            if (entry)
                entry.execute();
            else
                Quickshell.execDetached([action.appId]);
        } else if (action.kind === "quit") {
            const windows = Hyprland.toplevels.values.map(toplevel => ({
                appId: windowAppId(toplevel),
                address: toplevel.address
            }));
            for (const command of AppMenuModel.quitCommands(action.appId, windows))
                Quickshell.execDetached(command);
        } else if (action.kind === "window") {
            const command = AppMenuModel.windowCommand(action);
            if (command)
                Quickshell.execDetached(command);
        } else if (action.kind === "openPanel") {
            const command = AppMenuModel.openPanelCommand(action.panel, Quickshell.shellDir);
            if (command.length > 0)
                Quickshell.execDetached(command);
        } else if (action.kind === "dbusMenu" || action.kind === "gtkAction") {
            if (bridge)
                bridge.activate(action);
        }
    }
}
