import QtQuick

// Holds a popup's reveal back until its window has drawn its first frames.
// A popup's window is mapped afresh each time it opens, and those first
// frames are slow (the scene graph is built and its text and shapes are
// uploaded, 50–80 ms on the main thread), so a reveal started at once lost
// its first part in one jump and the capsule, on the same thread, froze
// while growing. The window is mapped while it is fully transparent instead,
// and `ready` turns true `frames` frames after it is on screen: the reveal,
// and what the bar draws round the popup, start from there.
Item {
    id: root

    // Whether the popup is open.
    property bool open: false
    // Whether its window is on screen (the window's `backingWindowVisible`).
    property bool mapped: false
    // How many frames the window draws, still transparent, before `ready`.
    property int frames: 2
    // True from that frame on; false again once the window is off screen.
    // Opening again while it is still on screen (mid-close) is ready at once.
    readonly property bool ready: state.warm && open

    onMappedChanged: {
        if (!mapped)
            state.warm = false;
    }

    QtObject {
        id: state

        property bool warm: false
    }

    FrameAnimation {
        running: root.open && root.mapped && !state.warm
        onTriggered: {
            if (currentFrame >= root.frames)
                state.warm = true;
        }
    }
}
