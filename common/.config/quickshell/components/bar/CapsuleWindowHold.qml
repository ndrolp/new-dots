import QtQuick

// How much taller a capsule's bar window is held for a popup inside it: as
// much as the popup needs as soon as it needs more, and what it needs last
// only `shrinkDelay` after it last needed less, once the capsule has shrunk.
// So the window is resized once per change rather than every frame, and never
// cuts off a capsule still shrinking.
Item {
    id: root

    // How much taller the window must be now, in px.
    property real needed: 0
    // How long the window waits before it shrinks, in ms.
    property int shrinkDelay: 0
    // How much taller the window is held, in px.
    readonly property alias held: state.held

    onNeededChanged: {
        if (needed >= state.held) {
            shrinkTimer.stop();
            state.held = needed;
        } else {
            shrinkTimer.restart();
        }
    }

    QtObject {
        id: state

        property real held: 0
    }

    Timer {
        id: shrinkTimer

        interval: root.shrinkDelay
        onTriggered: state.held = root.needed
    }
}
