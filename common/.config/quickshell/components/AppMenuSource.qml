import Quickshell
import Quickshell.Hyprland
import QtQuick
import "AppMenuModel.js" as AppMenuModel
import "FocusedWindow.js" as FocusedWindow

// The app menu's live side: the focused app and its .desktop file, the menus
// it exports (through the bridge), the menus AppMenuModel builds for it, and
// running the actions those menus hand over. Anything showing the app menu
// (its bar element and Popup, the popover) keeps one; the menus themselves
// are AppMenuModel's.
QtObject {
    id: root

    // The app menu module (modules/AppMenu.qml): the bridge and the panels
    // the Desktop menu opens. Without one, only the shell's menus show and
    // openPanel does nothing.
    property var appMenu: null
    readonly property var bridge: appMenu ? appMenu.bridge : null
    // Whether what keeps this source shows the app menu right now: the
    // bridge only runs while something does (AppMenuBridge.setUsing).
    property bool showing: false
    readonly property bool usingBridge: showing && bridge !== null

    readonly property var focusedWindow: FocusedWindow.focusedWindow(Hyprland.activeToplevel,
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

    onUsingBridgeChanged: {
        if (bridge)
            bridge.setUsing(root, usingBridge);
    }
    Component.onCompleted: {
        if (usingBridge)
            bridge.setUsing(root, true);
    }
    Component.onDestruction: {
        if (bridge)
            bridge.setUsing(root, false);
    }

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

    // How each kind of action from AppMenuModel's menus runs; a new kind
    // gets its entry here.
    readonly property var actionHandlers: ({
        desktopAction: action => {
            const entry = entryFor(action.appId);
            const desktopAction = entry
                ? entry.actions.find(candidate => candidate.id === action.actionId) : null;
            if (desktopAction)
                desktopAction.execute();
        },
        newWindow: action => {
            const entry = entryFor(action.appId);
            if (entry)
                entry.execute();
            else
                Quickshell.execDetached([action.appId]);
        },
        quit: action => {
            const windows = Hyprland.toplevels.values.map(toplevel => ({
                appId: windowAppId(toplevel),
                address: toplevel.address
            }));
            for (const command of AppMenuModel.quitCommands(action.appId, windows))
                Quickshell.execDetached(command);
        },
        window: action => {
            const command = AppMenuModel.windowCommand(action);
            if (command)
                Quickshell.execDetached(command);
        },
        openPanel: action => {
            if (appMenu)
                appMenu.openPanel(action.panel);
        },
        dbusMenu: action => {
            if (bridge)
                bridge.activate(action);
        },
        gtkAction: action => {
            if (bridge)
                bridge.activate(action);
        }
    })

    // Runs an action from AppMenuModel's menus.
    function run(action) {
        const handler = actionHandlers[action.kind];
        if (handler)
            handler(action);
    }
}
