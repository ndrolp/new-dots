import Quickshell
import Quickshell.Io
import QtQuick

// The `keep-awake` IPC call: the keybind toggles the shell's keep-awake with
// the selected duration and the OSD says what happened. Only this toggle
// shows the OSD; the popup and the control center tile show their own state.
Scope {
    id: root

    required property var keepAwake
    required property var osd

    IpcHandler {
        target: "keep-awake"

        function toggle() {
            root.keepAwake.toggle();
            root.osd.showKeepAwake(root.keepAwake.on, root.keepAwake.duration);
        }
    }
}
