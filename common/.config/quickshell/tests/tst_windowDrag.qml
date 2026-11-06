import QtQuick
import QtTest
import "../components/panels"

// Dragging a window between workspaces, driven with a real pointer: what counts
// as a click, what counts as a drop, and what ends a drag early.
Item {
    id: scene

    width: 400
    height: 200

    property var clicks: []
    property var drops: []

    QtObject {
        id: kitty
    }

    Component {
        id: closingWindow

        QtObject {}
    }

    // A window's item, which goes away with its miniature while it's being dragged.
    Component {
        id: windowItem

        Rectangle {
            property var pressWith: () => drag.press(kitty, true)

            x: 10
            y: 10
            width: 60
            height: 60

            MouseArea {
                anchors.fill: parent
                onPressed: parent.pressWith()
            }
        }
    }

    MouseArea {
        id: background

        property int clicks: 0

        anchors.fill: parent
        onClicked: clicks++
    }

    WindowDropTarget {
        id: elsewhere

        x: 200
        y: 10
        width: 60
        height: 60
        onWindowDropped: window => scene.drops.push({ window: window, on: "elsewhere" })
    }

    WindowDropTarget {
        id: ownWorkspace

        x: 300
        y: 10
        width: 60
        height: 60
        accepts: window => false
        onWindowDropped: window => scene.drops.push({ window: window, on: "ownWorkspace" })
    }

    WindowDrag {
        id: drag

        anchors.fill: parent
        z: 1
        ghost: Component {
            Item {}
        }
        onClicked: window => scene.clicks.push(window)
    }

    TestCase {
        name: "WindowDrag"
        when: windowShown

        property Item item: null

        function init() {
            scene.clicks = [];
            scene.drops = [];
            background.clicks = 0;
            item = createTemporaryObject(windowItem, scene);
        }

        function moveTo(x, y) {
            mouseMove(scene, x, y);
            wait(20);
        }

        function pressOnWindow() {
            mousePress(scene, 40, 40);
        }

        function dragTo(x, y) {
            pressOnWindow();
            moveTo(x, y);
        }

        function test_aPressThatStaysPutIsAClick() {
            pressOnWindow();
            mouseRelease(scene, 40, 40);

            compare(scene.clicks, [kitty]);
            compare(scene.drops, []);
        }

        function test_aPressThatTravelsTooLittleIsStillAClick() {
            pressOnWindow();
            moveTo(43, 42);
            verify(!drag.dragging);
            mouseRelease(scene, 43, 42);

            compare(scene.clicks, [kitty]);
        }

        function test_aPressThatTravelsFarEnoughStartsADragAndIsNoClick() {
            dragTo(60, 40);
            verify(drag.dragging);
            mouseRelease(scene, 60, 40);

            compare(scene.clicks, []);
            verify(!drag.dragging);
        }

        function test_aWorkspaceLightsUpWhileTheWindowIsOverIt() {
            dragTo(230, 40);
            tryVerify(() => elsewhere.containsDrag);

            moveTo(100, 150);
            tryVerify(() => !elsewhere.containsDrag);
            mouseRelease(scene, 100, 150);
        }

        function test_droppingOnAWorkspaceHandsItTheWindow() {
            dragTo(230, 40);
            mouseRelease(scene, 230, 40);

            compare(scene.drops, [{ window: kitty, on: "elsewhere" }]);
            compare(scene.clicks, []);
        }

        function test_droppingOnAGapDoesNothing() {
            dragTo(100, 150);
            mouseRelease(scene, 100, 150);

            compare(scene.drops, []);
            compare(scene.clicks, []);
            compare(background.clicks, 0);
        }

        function test_aWorkspaceThatRefusesTheWindowNeitherLightsUpNorTakesIt() {
            dragTo(330, 40);
            verify(!ownWorkspace.containsDrag);
            mouseRelease(scene, 330, 40);

            compare(scene.drops, []);
        }

        function test_aPinnedWindowDoesNotDrag() {
            item.pressWith = () => drag.press(kitty, false);
            dragTo(230, 40);
            verify(!drag.dragging);
            verify(!elsewhere.containsDrag);
            mouseRelease(scene, 230, 40);

            compare(scene.drops, []);
        }

        function test_aPinnedWindowCarriedAwayIsNoClickEither() {
            item.pressWith = () => drag.press(kitty, false);
            dragTo(230, 40);
            mouseRelease(scene, 230, 40);

            compare(scene.clicks, []);
        }

        function test_aPinnedWindowCanStillBeClicked() {
            item.pressWith = () => drag.press(kitty, false);
            pressOnWindow();
            mouseRelease(scene, 40, 40);

            compare(scene.clicks, [kitty]);
        }

        function test_aDragSurvivesItsWindowsItemGoingAway() {
            dragTo(120, 40);
            verify(drag.dragging);

            item.destroy();
            wait(0);
            verify(drag.dragging);

            moveTo(230, 40);
            tryVerify(() => elsewhere.containsDrag);
            mouseRelease(scene, 230, 40);

            compare(scene.drops, [{ window: kitty, on: "elsewhere" }]);
            compare(background.clicks, 0);
        }

        function test_aDragSurvivesThePointerLeavingTheView() {
            dragTo(120, 40);

            mouseMove(scene, 120, -30);
            wait(0);
            verify(drag.dragging);

            moveTo(230, 40);
            mouseRelease(scene, 230, 40);

            compare(scene.drops, [{ window: kitty, on: "elsewhere" }]);
        }

        function test_cancellingEndsTheDragAndReleasingThenDoesNothing() {
            dragTo(230, 40);
            tryVerify(() => elsewhere.containsDrag);

            drag.cancel();
            verify(!drag.dragging);
            tryVerify(() => !elsewhere.containsDrag);
            mouseRelease(scene, 230, 40);

            compare(scene.drops, []);
            compare(scene.clicks, []);
        }

        function test_theDraggedWindowClosingCancelsQuietly() {
            const closing = closingWindow.createObject(scene);
            item.pressWith = () => drag.press(closing, true);
            dragTo(230, 40);
            tryVerify(() => elsewhere.containsDrag);

            closing.destroy();
            tryVerify(() => !drag.dragging);
            tryVerify(() => !elsewhere.containsDrag);
            mouseRelease(scene, 230, 40);

            compare(scene.drops, []);
            compare(scene.clicks, []);
        }

        function test_aWindowClosingUnderAPressIsNoClick() {
            const closing = closingWindow.createObject(scene);
            item.pressWith = () => drag.press(closing, true);
            pressOnWindow();

            closing.destroy();
            wait(0);
            mouseRelease(scene, 40, 40);

            compare(scene.clicks, []);
        }

        function test_theNextPressAfterADragStartsAfresh() {
            dragTo(230, 40);
            mouseRelease(scene, 230, 40);

            pressOnWindow();
            mouseRelease(scene, 40, 40);

            compare(scene.clicks, [kitty]);
            compare(scene.drops.length, 1);
        }

        function test_theGhostExistsOnlyDuringADrag() {
            verify(drag.ghostItem === null);

            dragTo(120, 40);
            verify(drag.ghostItem !== null);

            mouseRelease(scene, 120, 40);
            tryVerify(() => drag.ghostItem === null);
        }
    }
}
