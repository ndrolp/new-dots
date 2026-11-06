import QtQuick

// A press on a window, which ends as a click or as a drag onto a
// WindowDropTarget. Goes over everything it can be dragged across.
//
// A window's item only reports the press. Its miniature can be rebuilt at any moment
// while the workspaces change, and an item that's gone takes its mouse grab with
// it, so the pointer is followed from here, where it outlives them.
Item {
    id: root

    // Built to follow the pointer during a drag, centred on it.
    property Component ghost: null
    // The window pressed. Null once the press is over, cancelled or the window
    // has closed.
    property QtObject window: null
    property bool draggable: false
    property bool travelled: false
    readonly property bool dragging: window !== null && draggable && travelled

    signal clicked(QtObject window)

    function press(pressed, canDrag) {
        window = pressed;
        draggable = canDrag;
        travelled = false;
    }

    function cancel() {
        window = null;
    }

    function follow() {
        const point = pointer.point;
        // How far a press travels before it stops being a click, in pixels.
        const clickTravel = 8;

        if (window === null)
            return;

        // Before the drag starts: it's dropped from where the drag source is.
        dragSource.x = point.position.x;
        dragSource.y = point.position.y;
        travelled = travelled || Math.hypot(point.position.x - point.pressPosition.x,
            point.position.y - point.pressPosition.y) >= clickTravel;
    }

    function release() {
        if (dragging)
            dragSource.Drag.drop();
        else if (window !== null && !travelled)
            clicked(window);

        cancel();
    }

    onWindowChanged: {
        if (window === null)
            travelled = false;
    }

    PointHandler {
        id: pointer

        onPointChanged: root.follow()
        onActiveChanged: {
            if (!active)
                root.release();
        }
    }

    Item {
        id: dragSource

        readonly property QtObject window: root.window

        Drag.active: root.dragging
        Drag.keys: ["window"]

        Loader {
            anchors.centerIn: parent
            active: root.dragging
            sourceComponent: root.ghost
        }
    }
}
