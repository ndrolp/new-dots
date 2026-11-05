import QtQuick
import "BarElementItems.js" as BarElementItems

// Closes the open popup when a bar element that opens none is pressed. It lies
// over the bar, because a handler under an element never sees a press the
// element took, and only watches, so the press still reaches the element. It
// acts on the press, ahead of the element's own click: the settings panel can't
// take the keyboard until the popup's focus grab is gone. Empty bar space and
// the elements with a popup, which toggle it themselves, are left alone.
Item {
    id: root

    // The item of every bar element, by element id.
    required property var elementItems

    signal closeRequested()

    // The element at `position`, in this item's coordinates, or "".
    function elementAt(position) {
        return Object.keys(elementItems).find(element => {
            const item = elementItems[element];
            return item.visible && item.contains(root.mapToItem(item, position));
        }) || "";
    }

    anchors.fill: parent
    z: 1

    PointHandler {
        acceptedButtons: Qt.AllButtons
        onActiveChanged: {
            if (!active)
                return;

            const element = root.elementAt(point.position);
            if (element !== "" && !BarElementItems.opensPopup(element))
                root.closeRequested();
        }
    }
}
