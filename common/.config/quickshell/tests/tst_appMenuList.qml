import QtQuick
import QtTest
import "../components/panels" as Panels
import "../config/Motion.js" as Motion

// How a menu of the app menu model is drawn: its items as rows, separators
// as rules, a submenu opening in place with a way back, and choosing an item
// handing over its action. Pointer events don't reach items under
// qmltestrunner offscreen, so items are chosen through `choose`.
TestCase {
    name: "AppMenuList"
    width: 400
    height: 400
    when: windowShown
    visible: true

    QtObject {
        id: barAppearance

        property int radius: 12
        property int textSize: 13
        readonly property var motion: Motion.motion(false)
    }

    readonly property var moveTo: ({ kind: "moveToWorkspace", workspace: 2 })
    readonly property var items: [
        { kind: "action", label: "New Private Window", action: { kind: "desktopAction", actionId: "private" } },
        { kind: "separator" },
        { kind: "submenu", label: "Move to Workspace", items: [
            { kind: "action", label: "Workspace 2", action: moveTo }
        ] },
        { kind: "action", label: "Quit Firefox", action: { kind: "quit", appId: "firefox" } }
    ]

    Component {
        id: list

        Panels.AppMenuList {
            appearance: barAppearance
            width: 240
        }
    }

    SignalSpy {
        id: chosen

        signalName: "actionChosen"
    }

    function all(item, predicate, found) {
        found = found || [];
        if (predicate(item))
            found.push(item);
        for (let i = 0; i < item.children.length; i++)
            all(item.children[i], predicate, found);
        return found;
    }

    function shownTexts(item) {
        return all(item, child => child.text !== undefined && child.font !== undefined
            && child.visible && child.text !== "").map(child => child.text);
    }

    function make() {
        const menu = createTemporaryObject(list, this, { items: items });
        chosen.clear();
        chosen.target = menu;
        waitForRendering(menu);
        return menu;
    }

    function test_itShowsEveryItemWithSubmenusMarked() {
        const menu = make();

        compare(shownTexts(menu), ["New Private Window", "Move to Workspace", "›", "Quit Firefox"]);
    }

    function test_aSeparatorIsARule() {
        const menu = make();

        compare(all(menu, child => child.separator === true && child.visible).length, 1);
    }

    function test_choosingAnActionHandsItOver() {
        const menu = make();

        menu.choose(3);

        compare(chosen.count, 1);
        compare(chosen.signalArguments[0][0], { kind: "quit", appId: "firefox" });
    }

    function test_choosingASeparatorDoesNothing() {
        const menu = make();

        menu.choose(1);

        compare(chosen.count, 0);
    }

    function test_aSubmenuOpensInPlaceWithAWayBack() {
        const menu = make();

        menu.choose(2);
        waitForRendering(menu);
        compare(shownTexts(menu), ["󰅁  Move to Workspace", "Workspace 2"]);

        menu.choose(0);
        compare(chosen.signalArguments[0][0], moveTo);

        menu.back();
        waitForRendering(menu);
        compare(shownTexts(menu), ["New Private Window", "Move to Workspace", "›", "Quit Firefox"]);
    }

    function test_newItemsStartAtTheTop() {
        const menu = make();

        menu.choose(2);
        menu.items = items.slice(0, 1);
        waitForRendering(menu);

        compare(shownTexts(menu), ["New Private Window"]);
    }
}
