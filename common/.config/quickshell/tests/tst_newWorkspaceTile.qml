import QtQuick
import QtTest
import "../components/panels"

// Dropping a window on the empty tile after a monitor's last workspace, driven
// with a real pointer through the same drag every workspace gets.
Item {
    id: scene

    width: 400
    height: 200

    property var drops: []
    property int backgroundClicks: 0

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

    NewWorkspaceTile {
        id: tile

        x: 200
        y: 10
        width: 100
        height: 60
        appearance: ({ radius: 8, textSize: 14, motion: { short: 0 } })
        colors: QtObject {
            readonly property color accent: "#ff0000"
            readonly property color border: "#444444"
            readonly property color textDisabled: "#888888"
        }
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
        name: "NewWorkspaceTile"
        when: windowShown

        readonly property point onWindow: Qt.point(40, 40)
        readonly property point onTile: Qt.point(250, 40)

        function init() {
            scene.drops = [];
            scene.backgroundClicks = 0;
            tile.workspace = 3;
        }

        function carryOver() {
            mousePress(scene, onWindow.x, onWindow.y);
            mouseMove(scene, onWindow.x + 20, onWindow.y);
            mouseMove(scene, onTile.x, onTile.y);
            waitForRendering(scene);
        }

        function test_droppingOnTheTileHandsOverTheWindowAndItsNumber() {
            carryOver();
            mouseRelease(scene, onTile.x, onTile.y);

            compare(scene.drops.length, 1);
            compare(scene.drops[0].window, kitty);
            compare(scene.drops[0].workspace, 3);
        }

        function test_theTileLightsUpWhileAWindowIsOverIt() {
            verify(!tile.lit);
            verify(Qt.colorEqual(tile.border.color, "#444444"));
            carryOver();
            verify(tile.lit);
            verify(Qt.colorEqual(tile.border.color, "#ff0000"));
            tryVerify(() => Qt.colorEqual(tile.color, Qt.rgba(1, 0, 0, 0.4)));
            drag.cancel();
            mouseRelease(scene, onTile.x, onTile.y);
        }

        function test_aWindowAlreadyOnThatNumberIsNotTaken() {
            tile.workspace = 2;
            carryOver();
            verify(!tile.lit);
            mouseRelease(scene, onTile.x, onTile.y);

            compare(scene.drops.length, 0);
        }

        // It isn't a workspace, so it counts as a click outside any workspace,
        // which closes the workspace overview.
        function test_aClickOnTheTileGoesThroughToWhatIsBehindIt() {
            mouseClick(scene, onTile.x, onTile.y);

            compare(scene.backgroundClicks, 1);
        }
    }
}
