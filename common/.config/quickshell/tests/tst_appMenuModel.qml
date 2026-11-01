import QtQuick
import QtTest
import "../components/AppMenuModel.js" as AppMenuModel

// The app menu's model: the menus for the focused window, as plain data.
TestCase {
    name: "AppMenuModel"

    readonly property var firefox: ({
        appId: "firefox",
        entry: {
            name: "Firefox",
            actions: [
                { id: "new-window", name: "New Window" },
                { id: "new-private-window", name: "New Private Window" }
            ]
        }
    })

    function labels(items) {
        return items.map(item => item.kind === "separator" ? "-" : item.label);
    }

    function test_theAppNameMenuIsTitledWithTheDesktopName() {
        const menu = AppMenuModel.appNameMenu(firefox);

        compare(menu.title, "Firefox");
        compare(menu.id, "app");
    }

    function test_anAppWithoutADesktopFileIsNamedByItsAppId() {
        const menu = AppMenuModel.appNameMenu({ appId: "org.example.Tool", entry: null });

        compare(menu.title, "org.example.Tool");
        compare(labels(menu.items), ["New Window", "-", "Quit org.example.Tool"]);
    }

    // Firefox's own "New Window" action would repeat the shell's.
    function test_theDesktopActionsComeFirstThenNewWindowAndQuit() {
        const menu = AppMenuModel.appNameMenu(firefox);

        compare(labels(menu.items), ["New Private Window", "-", "New Window", "-", "Quit Firefox"]);
    }

    function test_eachItemSaysWhatItDoesAsData() {
        const items = AppMenuModel.appNameMenu(firefox).items;

        compare(items[0].action, { kind: "desktopAction", appId: "firefox", actionId: "new-private-window" });
        compare(items[2].action, { kind: "newWindow", appId: "firefox" });
        compare(items[4].action, { kind: "quit", appId: "firefox" });
        compare(items[4].kind, "action");
    }

    // The menus are a list, so later ones (Window, Desktop, the app's own)
    // join it.
    function test_theFocusedAppGetsItsAppNameMenu() {
        const menus = AppMenuModel.menus({ app: firefox });

        compare(menus.map(menu => menu.id), ["app"]);
        compare(menus[0].title, "Firefox");
    }

    // An empty workspace: the app menu shows Desktop instead of an app.
    function test_noFocusedAppGetsTheDesktopMenu() {
        const menus = AppMenuModel.menus({ app: null });

        compare(menus.map(menu => menu.id), ["desktop"]);
        compare(menus[0].title, "Desktop");
    }

    function test_theDesktopMenuOpensTheShellsPanels() {
        const items = AppMenuModel.desktopMenu().items;

        compare(labels(items), ["Open Launcher", "Settings Panel", "Change Wallpaper"]);
        compare(items.map(item => item.action), [
            { kind: "openPanel", panel: "unifiedSearch" },
            { kind: "openPanel", panel: "settings" },
            { kind: "openPanel", panel: "wallpaperSelector" }
        ]);
    }

    // Opening goes through each panel's IPC handler, as the keybinds do.
    function test_aPanelOpensThroughItsIpcHandler() {
        compare(AppMenuModel.openPanelCommand("unifiedSearch", "/home/me/.config/quickshell"),
            ["quickshell", "ipc", "--path", "/home/me/.config/quickshell", "call", "unified-search", "show"]);
        compare(AppMenuModel.openPanelCommand("settings", "/s")[5], "config");
        compare(AppMenuModel.openPanelCommand("wallpaperSelector", "/s")[5], "wallpapers");
        compare(AppMenuModel.openPanelCommand("nope", "/s"), []);
    }

    // Like CurrentApp: Hyprland's active window counts only while it is on
    // the focused workspace.
    function test_theFocusedWindowIsTheActiveOneOnTheFocusedWorkspace() {
        const window = { workspace: { id: 3 } };

        compare(AppMenuModel.focusedWindow(window, { id: 3 }), window);
        compare(AppMenuModel.focusedWindow(window, { id: 4 }), null);
        compare(AppMenuModel.focusedWindow({ workspace: null }, { id: 3 }), null);
        compare(AppMenuModel.focusedWindow(null, { id: 3 }), null);
        compare(AppMenuModel.focusedWindow(window, null), null);
    }

    function test_quitPolitelyClosesEveryWindowOfTheApp() {
        const windows = [
            { appId: "firefox", address: "0xa1" },
            { appId: "kitty", address: "0xb2" },
            { appId: "firefox", address: "c3" }
        ];

        compare(AppMenuModel.quitCommands("firefox", windows), [
            ["hyprctl", "dispatch", "hl.dsp.window.close({ window = \"address:0xa1\" })"],
            ["hyprctl", "dispatch", "hl.dsp.window.close({ window = \"address:0xc3\" })"]
        ]);
    }

    function test_quitSkipsWindowsWithoutAUsableAddress() {
        const windows = [
            { appId: "firefox", address: "" },
            { appId: "firefox", address: "0x1\" }) evil" }
        ];

        compare(AppMenuModel.quitCommands("firefox", windows), []);
    }

    // The Window menu (#107): acting on the focused window through Hyprland.
    readonly property var tiledWindow: ({ address: "0xa1", floating: false, fullscreen: false, pinned: false })

    function test_theWindowMenuComesAfterTheAppNameMenu() {
        const menus = AppMenuModel.menus({ app: firefox, window: tiledWindow });

        compare(menus.map(menu => menu.id), ["app", "window"]);
        compare(menus[1].title, "Window");
    }

    function test_noFocusedWindowHasNoWindowMenu() {
        compare(AppMenuModel.menus({ app: firefox, window: null }).map(menu => menu.id), ["app"]);
    }

    function test_aTiledWindowOffersFloatFullscreenPinMoveAndClose() {
        const menu = AppMenuModel.windowMenu(tiledWindow);

        compare(labels(menu.items), ["Float", "Fullscreen", "Pin", "-", "Move to Workspace", "-", "Close Window"]);
    }

    function test_theLabelsFollowTheWindowsState() {
        const menu = AppMenuModel.windowMenu({ address: "0xa1", floating: true, fullscreen: true, pinned: true });

        compare(labels(menu.items).slice(0, 3), ["Tile", "Exit Fullscreen", "Unpin"]);
    }

    function test_moveToWorkspaceIsASubmenuOfWorkspacesOneToTen() {
        const move = AppMenuModel.windowMenu(tiledWindow).items[4];

        compare(move.kind, "submenu");
        compare(labels(move.items), ["Workspace 1", "Workspace 2", "Workspace 3", "Workspace 4", "Workspace 5",
            "Workspace 6", "Workspace 7", "Workspace 8", "Workspace 9", "Workspace 10"]);
        compare(move.items[2].action, { kind: "window", operation: "moveToWorkspace", address: "0xa1", workspace: 3 });
    }

    function test_eachWindowItemActsOnThatWindow() {
        const items = AppMenuModel.windowMenu(tiledWindow).items;

        compare(items[0].action, { kind: "window", operation: "toggleFloating", address: "0xa1" });
        compare(items[1].action, { kind: "window", operation: "toggleFullscreen", address: "0xa1" });
        compare(items[2].action, { kind: "window", operation: "togglePin", address: "0xa1" });
        compare(items[6].action, { kind: "window", operation: "close", address: "0xa1" });
    }

    function test_windowActionsBecomeHyprlandDispatches() {
        function command(operation, extra) {
            return AppMenuModel.windowCommand(Object.assign({ kind: "window", operation: operation, address: "a1" }, extra));
        }

        compare(command("toggleFloating"),
            ["hyprctl", "dispatch", "hl.dsp.window.float({ action = \"toggle\", window = \"address:0xa1\" })"]);
        compare(command("toggleFullscreen"),
            ["hyprctl", "dispatch", "hl.dsp.window.fullscreen({ action = \"toggle\", window = \"address:0xa1\" })"]);
        compare(command("togglePin"),
            ["hyprctl", "dispatch", "hl.dsp.window.pin({ window = \"address:0xa1\" })"]);
        compare(command("moveToWorkspace", { workspace: 7 }),
            ["hyprctl", "dispatch", "hl.dsp.window.move({ workspace = 7, window = \"address:0xa1\" })"]);
        compare(command("close"),
            ["hyprctl", "dispatch", "hl.dsp.window.close({ window = \"address:0xa1\" })"]);
    }

    function test_aWindowActionWithoutAUsableAddressOrWorkspaceDoesNothing() {
        compare(AppMenuModel.windowCommand({ kind: "window", operation: "close", address: "0x1\" }) evil" }), null);
        compare(AppMenuModel.windowCommand({ kind: "window", operation: "moveToWorkspace", address: "0xa1", workspace: "1 }) evil" }), null);
        compare(AppMenuModel.windowCommand({ kind: "window", operation: "unknown", address: "0xa1" }), null);
    }

    // A DBusMenu layout as the bridge hands it over: [id, properties, children].
    readonly property var electronMenu: ({
        kind: "dbusmenu",
        service: ":1.42",
        path: "/com/canonical/menu/1",
        layout: [0, { "children-display": "submenu" }, [
            [1, { label: "_File", "children-display": "submenu" }, [
                [11, { label: "_Open…", "type": "standard" }, []],
                [12, { type: "separator" }, []],
                [13, { label: "Save", enabled: false }, []],
                [14, { label: "Hidden", visible: false }, []]
            ]],
            [2, { label: "_View", "children-display": "submenu" }, [
                [21, { label: "Show Sidebar", "toggle-type": "checkmark", "toggle-state": 1 }, []],
                [22, { label: "Zoom", "children-display": "submenu" }, [
                    [221, { label: "Zoom __In" }, []]
                ]]
            ]],
            [3, { label: "Loose item" }, []]
        ]]
    })

    function test_aDBusMenuGivesOneMenuPerTopLevelTitle() {
        const menus = AppMenuModel.exportedMenus(electronMenu);

        compare(menus.map(menu => menu.title), ["File", "View"]);
        compare(labels(menus[0].items), ["Open…", "-", "Save"]);
        compare(menus[0].items[2].enabled, false);
    }

    function test_dBusMenuItemsKeepTheirSubmenusChecksAndMnemonicUnderscores() {
        const view = AppMenuModel.exportedMenus(electronMenu)[1];

        compare(labels(view.items), ["✓ Show Sidebar", "Zoom"]);
        compare(view.items[1].kind, "submenu");
        compare(labels(view.items[1].items), ["Zoom _In"]);
    }

    function test_choosingADBusMenuItemClicksItInTheApp() {
        const open = AppMenuModel.exportedMenus(electronMenu)[0].items[0];

        compare(open.action, { kind: "dbusMenu", service: ":1.42", path: "/com/canonical/menu/1", itemId: 11 });
    }

    // A GTK menubar as appmenu-gtk-module exports it (taken from Nemo):
    // sections and submenus point at other menus by [group, menu].
    readonly property var nemoMenu: ({
        kind: "gtk",
        service: ":1.256",
        menuPath: "/org/appmenu/gtk/window/0",
        actionPaths: { unity: "/org/appmenu/gtk/window/0", app: "/org/Nemo", win: "/org/Nemo/window/1" },
        menus: [
            [0, 0, [{ ":section": [0, 1] }]],
            [0, 1, [{ ":section": [0, 2] }]],
            [0, 2, [
                { action: "unity.-File", label: "_File", ":submenu": [1, 0] },
                { action: "unity.-View", label: "_View", ":submenu": [2, 0] },
                { action: "unity.-Go", label: "_Go", ":submenu": [3, 0] }
            ]],
            [1, 0, [{ ":section": [1, 1] }, { ":section": [1, 2] }, { ":section": [1, 3] }]],
            [1, 1, [
                { action: "unity.New--Tab", label: "New _Tab", accel: "<Primary>t" },
                { action: "unity.Create-New--Document", label: "Create New _Document", ":submenu": [7, 0] }
            ]],
            [1, 2, []],
            [1, 3, [{ action: "unity.-Close", label: "_Close" }]],
            [7, 0, [{ action: "unity.-Empty-Document", label: "_Empty Document" }]],
            [2, 0, [
                { action: "unity.Show-Hidden", label: "Show _Hidden Files" },
                { action: "unity.-Sort", label: "By _Name", target: "name" },
                { action: "app.zoom", label: "Zoom In" }
            ]]
        ],
        actions: {
            "unity.-Close": [false, "", []],
            "unity.Show-Hidden": [true, "", [true]],
            "unity.-Sort": [true, "s", ["name"]],
            "app.zoom": [true, "", []]
        }
    })

    function test_aGtkMenubarGivesOneMenuPerTopLevelTitle() {
        const menus = AppMenuModel.exportedMenus(nemoMenu);

        compare(menus.map(menu => menu.title), ["File", "View", "Go"]);
        compare(menus.map(menu => menu.id), ["global:0", "global:1", "global:2"]);
    }

    // Sections run on, with a separator between the ones that have items.
    function test_gtkSectionsAreSeparatedAndSubmenusNest() {
        const file = AppMenuModel.exportedMenus(nemoMenu)[0];

        compare(labels(file.items), ["New Tab", "Create New Document", "-", "Close"]);
        compare(labels(file.items[1].items), ["Empty Document"]);
        compare(file.items[3].enabled, false);
    }

    function test_gtkStatefulActionsShowWhetherTheyAreOn() {
        const view = AppMenuModel.exportedMenus(nemoMenu)[1];

        compare(labels(view.items), ["✓ Show Hidden Files", "• By Name", "Zoom In"]);
    }

    function test_choosingAGtkItemActivatesItsActionWhereThePrefixLives() {
        const view = AppMenuModel.exportedMenus(nemoMenu)[1];

        compare(view.items[0].action, { kind: "gtkAction", service: ":1.256",
            path: "/org/appmenu/gtk/window/0", name: "Show-Hidden" });
        compare(view.items[1].action, { kind: "gtkAction", service: ":1.256",
            path: "/org/appmenu/gtk/window/0", name: "-Sort", target: "name", targetType: "s" });
        compare(view.items[2].action.path, "/org/Nemo");
    }

    // Blueman's Device menu labels its items with markup.
    function test_markupInAGtkLabelIsLeftOut() {
        const exported = { kind: "gtk", service: ":1.293", actionPaths: { unity: "/m" }, actions: {}, menus: [
            [0, 0, [{ label: "_Device", ":submenu": [1, 0] }]],
            [1, 0, [{ action: "unity.Connect", label: "<b>_Connect</b>" }]]
        ] };

        compare(labels(AppMenuModel.exportedMenus(exported)[0].items), ["Connect"]);
    }

    function test_aGtkMenuNotYetLoadedIsAnEmptyMenu() {
        const go = AppMenuModel.exportedMenus(nemoMenu)[2];

        compare(go.items, []);
    }

    function test_theAppsOwnTitlesSitBetweenTheAppNameAndWindow() {
        const menus = AppMenuModel.menus({ app: firefox, window: tiledWindow, exported: nemoMenu });

        compare(menus.map(menu => menu.title), ["Firefox", "File", "View", "Go", "Window"]);
    }

    function test_anAppWithItsOwnWindowMenuRenamesTheShellsToHyprland() {
        const exported = { kind: "dbusmenu", service: ":1.9", path: "/menu", layout: [0, {}, [
            [1, { label: "_Window", "children-display": "submenu" }, []]
        ]] };
        const menus = AppMenuModel.menus({ app: firefox, window: tiledWindow, exported: exported });

        compare(menus.map(menu => menu.title), ["Firefox", "Window", "Hyprland"]);
        compare(menus[2].id, "window");
    }

    // App name, File, View, Go, Window: each title 100 wide, "»" 30.
    function nemoTitles() {
        return AppMenuModel.menus({ app: firefox, window: tiledWindow, exported: nemoMenu });
    }

    function test_titlesThatFitAreAllShown() {
        const shown = AppMenuModel.overflowSplit(nemoTitles(), [100, 100, 100, 100, 100], 500, 30);

        compare(shown.map(menu => menu.title), ["Firefox", "File", "View", "Go", "Window"]);
    }

    // 100 + 100 + 100 + Window 100 + » 30 = 430 fits 450, Go doesn't.
    function test_theAppsTitlesThatDontFitGoIntoATrailingOverflowMenu() {
        const shown = AppMenuModel.overflowSplit(nemoTitles(), [100, 100, 100, 100, 100], 450, 30);

        compare(shown.map(menu => menu.title), ["Firefox", "File", "View", "»", "Window"]);
        const overflow = shown[3];
        compare(overflow.items.map(item => [item.kind, item.label]), [["submenu", "Go"]]);
    }

    function test_theAppNameAndWindowStayEvenWhenNothingElseFits() {
        const shown = AppMenuModel.overflowSplit(nemoTitles(), [100, 100, 100, 100, 100], 150, 30);

        compare(shown.map(menu => menu.title), ["Firefox", "»", "Window"]);
        compare(shown[1].items.map(item => item.label), ["File", "View", "Go"]);
    }

    // The Popup finds the overflow menu by the id the bar element gave it.
    function test_theOverflowMenuCanBeFoundAgainByItsId() {
        const shown = AppMenuModel.overflowSplit(nemoTitles(), [100, 100, 100, 100, 100], 450, 30);
        const found = AppMenuModel.findMenu(nemoTitles(), shown[3].id);

        compare(found.title, "»");
        compare(found.items.map(item => item.label), ["Go"]);
        compare(AppMenuModel.findMenu(nemoTitles(), "window").title, "Window");
        compare(AppMenuModel.findMenu(nemoTitles(), "").title, "Firefox");
        compare(AppMenuModel.findMenu([], "window"), null);
    }

    function test_theDesktopMenuIgnoresWhatIsExported() {
        compare(AppMenuModel.menus({ app: null, window: null, exported: nemoMenu }).map(menu => menu.id),
            ["desktop"]);
    }

    function test_nothingExportedGivesNoMenus() {
        compare(AppMenuModel.exportedMenus(null), []);
        compare(AppMenuModel.exportedMenus({ kind: "dbusmenu", layout: null }), []);
    }
}
