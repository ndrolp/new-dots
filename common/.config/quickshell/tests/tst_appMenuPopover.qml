import QtQuick
import QtTest
import "../components/AppMenuModel.js" as AppMenuModel
import "../components/panels/AppMenuPopover.js" as AppMenuPopover

// The app menu popover's list: the app-name menu's items first, then every
// other menu of the app menu model as a submenu, so menus added to the model
// show up in it without more work.
TestCase {
    name: "AppMenuPopover"

    readonly property var quit: ({ kind: "action", label: "Quit Firefox", action: { kind: "quit", appId: "firefox" } })
    readonly property var appMenu: ({ id: "app", title: "Firefox", items: [quit] })
    readonly property var windowMenu: ({ id: "window", title: "Window", items: [
        { kind: "action", label: "Float", action: { kind: "float" } }
    ] })

    function test_withNoMenusItIsEmpty() {
        compare(AppMenuPopover.items([]), []);
    }

    function test_theAppNameMenuItemsComeFirst() {
        compare(AppMenuPopover.items([appMenu]), [quit]);
    }

    function test_everyOtherMenuIsASubmenuAfterASeparator() {
        compare(AppMenuPopover.items([appMenu, windowMenu]), [
            quit,
            { kind: "separator" },
            { kind: "submenu", label: "Window", items: windowMenu.items }
        ]);
    }

    // A focused app that exports its own menus (File, View) over DBusMenu.
    readonly property var exportingApp: ({ appId: "editor", entry: { name: "Editor", actions: [] } })
    readonly property var tiledWindow: ({ address: "0xa1", floating: false, fullscreen: false, pinned: false })
    readonly property var editorMenu: ({ kind: "dbusmenu", service: ":1.42", path: "/menu", layout: [0, {}, [
        [1, { label: "_File", "children-display": "submenu" }, [[11, { label: "_Open…" }, []]]],
        [2, { label: "_View", "children-display": "submenu" }, [[21, { label: "Zoom In" }, []]]]
    ]] })

    function popoverFor(exported) {
        return AppMenuPopover.items(AppMenuModel.menus({ app: exportingApp, window: tiledWindow, exported: exported }));
    }

    function test_anExportingAppsOwnMenusAreSubmenusBeforeWindow() {
        const submenus = popoverFor(editorMenu).filter(item => item.kind === "submenu");

        compare(submenus.map(item => item.label), ["File", "View", "Window"]);
    }

    function test_choosingAnItemInTheAppsOwnMenuClicksItInTheApp() {
        const file = popoverFor(editorMenu).find(item => item.label === "File");

        compare(file.items[0].action, { kind: "dbusMenu", service: ":1.42", path: "/menu", itemId: 11 });
    }

    function test_anAppExportingNothingShowsOnlyTheShellsMenus() {
        const submenus = popoverFor(null).filter(item => item.kind === "submenu");

        compare(submenus.map(item => item.label), ["Window"]);
    }

    // A 1920x1080 monitor to the right of another one; the cursor is in
    // global coordinates, the position in the monitor's.
    readonly property var screen: ({ x: 1920, y: 0, width: 1920, height: 1080 })

    function placed(cursor) {
        return AppMenuPopover.position({ cursor: cursor, screen: screen, width: 260, height: 300, margin: 8 });
    }

    function test_itOpensDownAndRightOfTheCursor() {
        compare(placed({ x: 2420, y: 200 }), { x: 500, y: 200 });
    }

    function test_nearTheRightEdgeItOpensLeftOfTheCursor() {
        compare(placed({ x: 3800, y: 200 }), { x: 1620, y: 200 });
    }

    function test_nearTheBottomEdgeItOpensAboveTheCursor() {
        compare(placed({ x: 2420, y: 1000 }), { x: 500, y: 700 });
    }

    function test_itStaysOnTheMonitorWhenItFitsNeitherWay() {
        compare(AppMenuPopover.position({ cursor: { x: 2000, y: 500 }, screen: screen,
            width: 260, height: 1000, margin: 8 }), { x: 80, y: 8 });
    }
}
