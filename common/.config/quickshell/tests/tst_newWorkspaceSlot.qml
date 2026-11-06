import QtQuick
import QtTest
import "../components/panels"
import "../config" as Config

// Dropping a window on the empty slot after a monitor's last workspace, driven
// with a real pointer through the same drag every workspace gets.
Item {
    id: scene

    width: 400
    height: 200

    property var drops: []
    property int backgroundClicks: 0

    Config.Theme {
        id: theme
    }

    QtObject {
        id: kitty

        readonly property var lastIpcObject: ({ workspace: { id: 2 } })
    }

    MouseArea {
        anchors.fill: parent
        onClicked: scene.backgroundClicks++
    }

    Rectangle {
        id: windowItem

        x: 10
        y: 10
        width: 60
        height: 60

        MouseArea {
            anchors.fill: parent
            onPressed: drag.press(kitty, true)
        }
    }

    NewWorkspaceSlot {
        id: slot

        x: 200
        y: 10
        width: 100
        height: 60
        appearance: ({ radius: 8, textSize: 14, motion: { short: 0 } })
        workspace: 3
        onWindowDropped: window => scene.drops.push({ window: window, workspace: workspace })
    }

    WindowDrag {
        id: drag

        anchors.fill: parent
        z: 1
        ghost: Component {
            Item {}
        }
    }

    TestCase {
        name: "NewWorkspaceSlot"
        when: windowShown

        readonly property point onWindow: Qt.point(40, 40)
        readonly property point onSlot: Qt.point(250, 40)

        function init() {
            scene.drops = [];
            scene.backgroundClicks = 0;
            slot.workspace = 3;
        }

        function carryOver() {
            mousePress(scene, onWindow.x, onWindow.y);
            mouseMove(scene, onWindow.x + 20, onWindow.y);
            mouseMove(scene, onSlot.x, onSlot.y);
            waitForRendering(scene);
        }

        function test_droppingOnTheSlotHandsOverTheWindowAndItsNumber() {
            carryOver();
            mouseRelease(scene, onSlot.x, onSlot.y);

            compare(scene.drops.length, 1);
            compare(scene.drops[0].window, kitty);
            compare(scene.drops[0].workspace, 3);
        }

        function test_theSlotLightsUpWhileAWindowIsOverIt() {
            verify(!slot.highlighted);
            verify(Qt.colorEqual(slot.border.color, theme.border));
            carryOver();
            verify(slot.highlighted);
            verify(Qt.colorEqual(slot.border.color, theme.accent));
            const lit = Qt.rgba(theme.accent.r, theme.accent.g, theme.accent.b, 0.4);
            tryVerify(() => Qt.colorEqual(slot.color, lit));
            drag.cancel();
            mouseRelease(scene, onSlot.x, onSlot.y);
        }

        function test_aWindowAlreadyOnThatNumberIsNotTaken() {
            slot.workspace = 2;
            carryOver();
            verify(!slot.highlighted);
            mouseRelease(scene, onSlot.x, onSlot.y);

            compare(scene.drops.length, 0);
        }

        // It isn't a workspace, so it counts as a click outside any workspace,
        // which closes the workspace overview.
        function test_aClickOnTheSlotGoesThroughToWhatIsBehindIt() {
            mouseClick(scene, onSlot.x, onSlot.y);

            compare(scene.backgroundClicks, 1);
        }
    }
}
