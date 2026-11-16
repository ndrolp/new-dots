import QtQuick

// When hovering the capsule expands it: after the pointer rests on it for a
// moment, so a quick pass doesn't, and until a while after the pointer leaves.
// These are timings, not animations: Reduce motion leaves them as they are.
Item {
    id: root

    // Whether the pointer is over the capsule now.
    property bool hovering: false
    // How long the pointer rests on the capsule before it expands, in ms.
    property int expandDelay: 150
    // How long the capsule stays expanded after the pointer leaves, in ms.
    property int collapseDelay: 400
    // Whether hovering holds the capsule expanded.
    readonly property alias expanded: state.expanded

    onHoveringChanged: {
        if (hovering) {
            collapseTimer.stop();
            if (!state.expanded)
                expandTimer.restart();
        } else {
            expandTimer.stop();
            if (state.expanded)
                collapseTimer.restart();
        }
    }

    QtObject {
        id: state

        property bool expanded: false
    }

    Timer {
        id: expandTimer

        interval: root.expandDelay
        onTriggered: state.expanded = true
    }

    Timer {
        id: collapseTimer

        interval: root.collapseDelay
        onTriggered: state.expanded = false
    }
}
