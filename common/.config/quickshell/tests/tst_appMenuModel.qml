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

    function test_noFocusedAppHasNoAppNameMenu() {
        compare(AppMenuModel.menus({ app: null }), []);
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
}
