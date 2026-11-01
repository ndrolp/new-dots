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
// An action is data saying what to do, run by AppMenuSource.run():
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

// Every menu for the focused window, in order. `context` is
// { app, window, exported }, `app` null when no window is focused, which
// gives the Desktop menu instead, `window` the focused window as windowMenu
// takes it (or null, leaving the Window menu out) and `exported` the app's
// own menus as the bridge hands them over (see exportedMenus), whose titles
// go between the app-name menu and Window. When the app has a Window menu
// of its own, the shell's is called Hyprland.
function menus(context) {
    if (!context.app)
        return [desktopMenu()];
    const own = exportedMenus(context.exported);
    const list = [appNameMenu(context.app)].concat(own);
    if (context.window) {
        const shellWindowMenu = windowMenu(context.window);
        if (own.some(menu => menu.title.toLowerCase() === "window"))
            shellWindowMenu.title = "Hyprland";
        list.push(shellWindowMenu);
    }
    return list;
}

const exportedPrefix = "exported:";

function isExportedMenu(menu) {
    return menu.id.startsWith(exportedPrefix);
}

const overflowPrefix = "overflow:";

// The "»" menu holding the app's own menus from `firstId` on, each as a
// submenu. Its id names that first one, so findMenu can build it again.
function overflowMenu(menuList, firstId) {
    const first = menuList.findIndex(menu => menu.id === firstId);
    const leftover = first < 0 ? [] : menuList.slice(first).filter(isExportedMenu);
    return {
        id: overflowPrefix + firstId,
        title: "»",
        items: leftover.map(menu => ({ kind: "submenu", label: menu.title, items: menu.items }))
    };
}

// The menus whose titles the app menu bar element shows, within
// `maximumWidth`: `widths` are their titles' widths in order and
// `overflowWidth` the "»" title's. The shell's menus always show; the app's
// own fill what's left in order, and once one doesn't fit, it and the rest
// go into a "»" menu right after the last that did.
function overflowSplit(menuList, widths, maximumWidth, overflowWidth) {
    const fixedWidth = menuList.reduce((sum, menu, index) =>
        isExportedMenu(menu) ? sum : sum + (widths[index] || 0), 0);
    const allWidth = menuList.reduce((sum, menu, index) => sum + (widths[index] || 0), 0);
    if (allWidth <= maximumWidth)
        return menuList;

    let room = maximumWidth - fixedWidth - overflowWidth;
    let firstLeftover = -1;
    menuList.forEach((menu, index) => {
        if (isExportedMenu(menu) && firstLeftover < 0) {
            if ((widths[index] || 0) <= room)
                room -= widths[index] || 0;
            else
                firstLeftover = index;
        }
    });
    return menuList
        .map((menu, index) => !isExportedMenu(menu) || index < firstLeftover ? menu
            : index === firstLeftover ? overflowMenu(menuList, menu.id) : null)
        .filter(menu => menu !== null);
}

// The menu called `id` among `menuList`, including a "»" menu
// overflowSplit made from it; the first menu when there's no such one, and
// null when there are none.
function findMenu(menuList, id) {
    if (id && id.startsWith(overflowPrefix))
        return overflowMenu(menuList, id.slice(overflowPrefix.length));
    return menuList.find(menu => menu.id === id) || menuList[0] || null;
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
// them does to it now. Pin is disabled while the window is tiled.
function windowMenu(window) {
    function windowAction(label, operation, extra) {
        return action(label, Object.assign({ kind: "window", operation: operation, address: window.address }, extra));
    }

    const workspaces = [];
    for (let workspace = 1; workspace <= 10; workspace++)
        workspaces.push(windowAction("Workspace " + workspace, "moveToWorkspace", { workspace: workspace }));

    // Hyprland only pins floating windows.
    const pinItem = windowAction(window.pinned ? "Unpin" : "Pin", "togglePin");
    if (!window.floating)
        pinItem.enabled = false;

    return {
        id: "window",
        title: "Window",
        items: [
            windowAction(window.floating ? "Tile" : "Float", "toggleFloating"),
            windowAction(window.fullscreen ? "Exit Fullscreen" : "Fullscreen", "toggleFullscreen"),
            pinItem,
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

// ---- The app's own menus ----------------------------------------------
//
// An app exports its menus over D-Bus, and the bridge
// (services/AppMenuBridge.qml) hands them over as they come ("exported"):
//   { kind: "dbusmenu", service, path, layout }
//       com.canonical.dbusmenu (Electron, Java, Qt on X11): `layout` is
//       GetLayout's tree as [id, properties, children].
//   { kind: "gtk", service, menuPath, actionPaths, menus, actions }
//       org.gtk.Menus (GTK apps through appmenu-gtk-module): `menus` is
//       Start's [group, menu, items] list, `actions` each action's
//       Describe as { "prefix.name": [enabled, parameterType, state] } and
//       `actionPaths` the object path of each action prefix.
// Their items run through two more actions:
//   { kind: "dbusMenu", service, path, itemId }  clicks a DBusMenu item
//   { kind: "gtkAction", service, path, name, target?, targetType? }
//                                                activates a GTK action

// "_File" -> "File", "Zoom __In" -> "Zoom _In": GTK and DBusMenu mark the
// mnemonic with an underscore, and double a literal one.
function withoutMnemonic(label) {
    return String(label || "").replace(/_(_?)/g, (match, literal) => literal);
}

// A check or radio item's label, marked when it's on.
function toggleLabel(label, toggleType, on) {
    if (!on)
        return label;
    return (toggleType === "radio" ? "• " : "✓ ") + label;
}

function dbusMenuItems(children, exported) {
    const items = [];
    for (const child of children || []) {
        const id = child[0];
        const properties = child[1] || {};
        const grandchildren = child[2] || [];
        if (properties.visible === false)
            continue;
        if (properties.type === "separator") {
            items.push(separator);
            continue;
        }
        const label = toggleLabel(withoutMnemonic(properties.label), properties["toggle-type"],
            properties["toggle-state"] === 1);
        let item;
        if (properties["children-display"] === "submenu" || grandchildren.length > 0)
            item = { kind: "submenu", label: label, items: dbusMenuItems(grandchildren, exported) };
        else
            item = action(label, { kind: "dbusMenu", service: exported.service, path: exported.path, itemId: id });
        if (properties.enabled === false)
            item.enabled = false;
        items.push(item);
    }
    return items;
}

// "<b>Connect</b>" -> "Connect": some GTK apps put Pango markup in labels.
function withoutMarkup(label) {
    return String(label || "").replace(/<[^>]*>/g, "")
        .replace(/&lt;/g, "<").replace(/&gt;/g, ">").replace(/&quot;/g, "\"").replace(/&amp;/g, "&");
}

function gtkItem(attributes, exported) {
    const fullName = attributes.action || "";
    const dot = fullName.indexOf(".");
    const description = exported.actions ? exported.actions[fullName] : undefined;
    const enabled = !description || description[0] !== false;
    if ((attributes["hidden-when"] === "action-missing" && !description)
        || (attributes["hidden-when"] === "action-disabled" && !enabled))
        return null;

    const state = description && description[2] && description[2].length > 0 ? description[2][0] : undefined;
    const hasTarget = attributes.target !== undefined;
    let label = withoutMnemonic(withoutMarkup(attributes.label));
    if (hasTarget && state !== undefined && state === attributes.target)
        label = toggleLabel(label, "radio", true);
    else if (!hasTarget && state === true)
        label = toggleLabel(label, "checkmark", true);

    let item;
    if (attributes[":submenu"]) {
        item = { kind: "submenu", label: label, items: gtkMenuItems(attributes[":submenu"], exported) };
    } else {
        const path = dot > 0 && exported.actionPaths ? exported.actionPaths[fullName.slice(0, dot)] : undefined;
        if (!path)
            return null;
        const what = { kind: "gtkAction", service: exported.service, path: path, name: fullName.slice(dot + 1) };
        if (hasTarget) {
            what.target = attributes.target;
            what.targetType = description && description[1] ? description[1] : "s";
        }
        item = action(label, what);
    }
    if (!enabled)
        item.enabled = false;
    return item;
}

// The items of the GTK menu at `link` ([group, menu]): its sections run on,
// a separator between the ones with items. [] while that menu isn't loaded.
function gtkMenuItems(link, exported) {
    const found = (exported.menus || []).find(entry => entry[0] === link[0] && entry[1] === link[1]);
    const groups = [[]];
    for (const attributes of found ? found[2] : []) {
        if (attributes[":section"]) {
            groups.push(gtkMenuItems(attributes[":section"], exported));
            groups.push([]);
        } else {
            const item = gtkItem(attributes, exported);
            if (item)
                groups[groups.length - 1].push(item);
        }
    }
    return groups
        .filter(group => group.length > 0)
        .reduce((items, group) => items.length > 0 ? items.concat([separator], group) : group, []);
}

// The app's own menus, one per top-level title, from what the bridge
// handed over (see above); [] for nothing or anything it doesn't know.
// Each gets the id "exported:<n>", n its place among them.
function exportedMenus(exported) {
    let submenus = [];
    if (exported && exported.kind === "dbusmenu" && exported.layout)
        submenus = dbusMenuItems(exported.layout[2], exported);
    else if (exported && exported.kind === "gtk")
        submenus = gtkMenuItems([0, 0], exported);
    return submenus
        .filter(item => item.kind === "submenu")
        .map((item, index) => ({ id: exportedPrefix + index, title: item.label, items: item.items }));
}
