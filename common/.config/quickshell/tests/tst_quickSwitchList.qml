import QtQuick
import QtTest
import "../components/panels" as Panels

// The quick switch's list: P moves down, Enter applies, Esc closes.
Item {
    id: scene

    width: 500
    height: 400

    QtObject {
        id: fakeAppearance

        property int radius: 8
        property int textSize: 13
        property var motion: ({ short: 0, easing: Easing.OutCubic })
    }

    Component {
        id: listComponent

        Panels.QuickSwitchList {
            width: 440
            appearance: fakeAppearance
            choices: [{ kind: "extend", label: "Extend" }, { kind: "mirror", label: "Mirror" },
                { kind: "only", label: "AOC only", port: "DP-2" }]
        }
    }

    Component {
        id: spyComponent

        SignalSpy {}
    }

    TestCase {
        name: "QuickSwitchList"
        when: windowShown

        function focused(properties) {
            const list = createTemporaryObject(listComponent, scene, properties || {});
            list.forceActiveFocus();
            return list;
        }

        function spyOn(list, signalName) {
            return createTemporaryObject(spyComponent, scene, { target: list, signalName: signalName });
        }

        function all(item, predicate, found) {
            found = found || [];
            if (predicate(item))
                found.push(item);
            for (let i = 0; i < item.children.length; i++)
                all(item.children[i], predicate, found);
            return found;
        }

        function test_showsEveryChoice() {
            const list = focused();
            waitForRendering(list);
            ["Extend", "Mirror", "AOC only"].forEach(label => {
                compare(all(list, child => child.text === label && child.visible).length, 1, label);
            });
        }

        function test_pAsksForTheNextChoice() {
            const list = focused({ currentIndex: 1 });
            const spy = spyOn(list, "selectionAsked");
            keyClick(Qt.Key_P);
            compare(spy.count, 1);
            compare(spy.signalArguments[0][0], 2);
        }

        function test_pGoesBackToTheTopFromTheLastChoice() {
            const list = focused({ currentIndex: 2 });
            const spy = spyOn(list, "selectionAsked");
            keyClick(Qt.Key_P);
            compare(spy.signalArguments[0][0], 0);
        }

        function test_enterAppliesTheSelectedChoice() {
            const list = focused({ currentIndex: 2 });
            const spy = spyOn(list, "chosen");
            keyClick(Qt.Key_Return);
            compare(spy.count, 1);
            compare(spy.signalArguments[0][0].port, "DP-2");
        }

        function test_theKeypadsEnterAppliesToo() {
            const list = focused();
            const spy = spyOn(list, "chosen");
            keyClick(Qt.Key_Enter);
            compare(spy.signalArguments[0][0].kind, "extend");
        }

        function test_escapeClosesWithoutApplying() {
            const list = focused();
            const chosen = spyOn(list, "chosen");
            const closing = spyOn(list, "closeAsked");
            keyClick(Qt.Key_Escape);
            compare(closing.count, 1);
            compare(chosen.count, 0);
        }

        function test_clickingAChoiceAppliesIt() {
            const list = focused();
            const spy = spyOn(list, "chosen");
            waitForRendering(list);
            mouseClick(all(list, child => child.text === "Mirror")[0]);
            compare(spy.signalArguments[0][0].kind, "mirror");
        }
    }
}
