import QtQuick
import QtTest
import "../components/bar"

// What gives a bar element's item its look in the capsule's row: the look's
// opacity and scale, and its slide along the row, following the look as it
// changes.
TestCase {
    name: "RowLook"
    width: 200
    height: 100
    visible: true
    when: windowShown

    Component {
        id: element

        Rectangle {
            property var look: ({ opacity: 0.5, scale: 0.9, slide: 6 })

            id: item

            x: 20
            width: 40
            height: 20
            color: "#ff0000"

            RowLook {
                target: item
                look: item.look
            }
        }
    }

    function test_theItemTakesTheLook() {
        const item = createTemporaryObject(element, this);

        compare(item.opacity, 0.5);
        compare(item.scale, 0.9);
        compare(item.transform.length, 1);
        compare(item.transform[0].x, 6);
        compare(item.mapToItem(null, 0, 0).x, 20 + 6 + 40 * 0.05);
    }

    function test_itFollowsTheLookAsItChanges() {
        const item = createTemporaryObject(element, this);

        item.look = { opacity: 1, scale: 1, slide: -3 };
        compare(item.opacity, 1);
        compare(item.scale, 1);
        compare(item.transform[0].x, -3);
    }
}
