import QtQuick
import QtTest
import "../components/bar"

// The pointer counts as over the capsule anywhere over it, glance cards
// included, though the bar content is only as deep as its row and the
// glance is drawn past it: BarContent's hover is masked to the capsule
// (CapsuleHoverMask), so hovering it doesn't stop at the content's edge.
Item {
    id: scene

    width: 600
    height: 200

    // As BarContent: as deep as its row, with the glance drawn past it, its
    // media card's play button hovered on its own.
    Item {
        id: content

        width: 600
        height: 30
        containmentMask: CapsuleHoverMask {
            place: ({ x: 150, y: 0, width: 300, height: 110, radius: 20 })
        }

        HoverHandler {
            id: pointer
        }

        Item {
            id: glance

            x: 150
            y: 40
            width: 300
            height: 70

            MouseArea {
                x: 0
                y: 0
                width: 60
                height: 70
                hoverEnabled: true
            }
        }
    }

    TestCase {
        name: "CapsuleHoverMask"
        when: windowShown

        function moveTo(x, y) {
            mouseMove(scene, x, y);
            wait(20);
        }

        function test_theRowIsHovered() {
            moveTo(500, 100);
            moveTo(300, 15);
            verify(pointer.hovered);
        }

        function test_movingOntoTheGlanceKeepsItHovered_data() {
            return [
                { tag: "a card", at: { x: 350, y: 80 } },
                { tag: "the play button", at: { x: 170, y: 80 } }
            ];
        }

        function test_movingOntoTheGlanceKeepsItHovered(data) {
            moveTo(300, 15);
            moveTo(data.at.x, data.at.y);
            verify(pointer.hovered);
        }

        function test_besideTheCapsuleIsNotHovered_data() {
            return [
                { tag: "beside the row", at: { x: 100, y: 15 } },
                { tag: "beside the glance", at: { x: 500, y: 80 } },
                { tag: "past the glance", at: { x: 300, y: 150 } }
            ];
        }

        function test_besideTheCapsuleIsNotHovered(data) {
            moveTo(300, 15);
            moveTo(data.at.x, data.at.y);
            verify(!pointer.hovered);
        }

        function test_withNoCapsuleNothingIsHovered() {
            content.containmentMask.place = null;
            moveTo(300, 15);
            verify(!pointer.hovered);
            content.containmentMask.place = { x: 150, y: 0, width: 300, height: 110, radius: 20 };
        }
    }
}
