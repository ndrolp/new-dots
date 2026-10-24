import QtQuick
import QtTest
import "../components/panels" as Panels
import "../config" as Config

// The Session section's controls, built from the settings parts: the session
// actions are quiet buttons, two per line. The section itself
// (SessionSettings.qml) runs the commands with Quickshell.Io, which doesn't
// load here, so these tests stop at the command each button asks to run.
TestCase {
    name: "SessionActions"
    width: 800
    height: 600
    when: windowShown

    Config.Theme {
        id: theme
    }

    function all(item, predicate, found) {
        found = found || [];
        if (predicate(item))
            found.push(item);
        for (let i = 0; i < item.children.length; i++)
            all(item.children[i], predicate, found);
        return found;
    }

    function button(item, label) {
        return all(item, child => child.label === label && child.activated !== undefined)[0];
    }

    Component {
        id: page

        Item {
            property alias actions: actions
            property var requested: []

            width: 700

            QtObject {
                id: appearance

                property int radius: 12
                property int textSize: 13
            }

            Panels.SessionActions {
                id: actions

                appearance: appearance
                onRequested: command => parent.requested = parent.requested.concat([command])
            }
        }
    }

    function make() {
        return createTemporaryObject(page, this);
    }

    function sameLine(item, first, second) {
        const a = first.mapToItem(item, 0, 0);
        const b = second.mapToItem(item, 0, 0);
        return a.y === b.y && a.x < b.x;
    }

    function test_eachActionIsAQuietButtonThatRunsItsCommand() {
        const built = make();
        const expected = [
            ["󰌾  Lock now", ["loginctl", "lock-session"]],
            ["󰍹  Turn displays off", ["hyprctl", "dispatch", "dpms", "off"]],
            ["󰤄  Suspend", ["systemctl", "suspend"]]
        ];

        for (const [label, command] of expected) {
            const action = button(built.actions, label);
            verify(action, label);
            compare(action.color, Qt.rgba(0, 0, 0, 0), label);
            action.activated();
            compare(built.requested[built.requested.length - 1], command, label);
        }
    }

    function test_actionsSitTwoPerLine() {
        const built = make();

        verify(sameLine(built.actions, button(built.actions, "󰌾  Lock now"),
            button(built.actions, "󰍹  Turn displays off")));
    }

    function test_nothingIsBoldAndNoFilledCardsRemain() {
        const built = make();
        const bold = all(built.actions, child => child.font !== undefined && child.font.bold);
        const cards = all(built.actions, child => child.color !== undefined && child.radius !== undefined
            && Qt.colorEqual(child.color, theme.backgroundSecondary));

        compare(bold.length, 0);
        compare(cards.length, 0);
    }
}
