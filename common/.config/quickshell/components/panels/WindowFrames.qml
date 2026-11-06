import Quickshell
import Quickshell.Wayland
import QtQuick

// One captured frame per window, held here rather than in a workspace's tile so a
// window keeps its frame when it moves to another tile: a new capture there could
// land on a hidden workspace, where Hyprland never answers.
//
// A ScreencopyView that isn't live captures once by itself when it gets its
// source, so a window gets its frame when it's first listed in `windows`, and
// nothing captures again. Taking a window off the list destroys its frame, along
// with a capture still waiting for an answer.
Item {
    id: frames

    // The toplevels to capture.
    property var windows: []

    // A frame is only ever drawn through a WindowThumbnail.
    visible: false

    // The ScreencopyView capturing a window, once there is one.
    function frameOf(toplevel) {
        // Read so that a binding on this looks again when a window appears.
        const count = captures.count;

        for (let index = 0; index < count; index++) {
            const frame = captures.itemAt(index);

            if (frame !== null && frame.toplevel === toplevel)
                return frame;
        }

        return null;
    }

    Repeater {
        id: captures

        model: ScriptModel {
            values: frames.windows
        }

        delegate: ScreencopyView {
            required property var modelData
            readonly property var toplevel: modelData

            live: false
            paintCursor: false
            captureSource: toplevel.wayland
        }
    }
}
